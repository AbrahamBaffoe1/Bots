#!/usr/bin/env python3
"""
MT5 Bridge - WebSocket Bridge for MetaTrader 5 EA Communication
Connects MT5 Expert Advisors to Python backend via WebSocket
Features: Real-time signal processing, trade execution, risk management
"""

import MetaTrader5 as mt5
import asyncio
import websockets
import json
import logging
import os
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
import requests
from dotenv import load_dotenv
import numpy as np
import time

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'mt5_bridge_{datetime.now().strftime("%Y%m%d")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configuration
MT5_LOGIN = int(os.getenv('MT5_LOGIN', '0'))
MT5_PASSWORD = os.getenv('MT5_PASSWORD', '')
MT5_SERVER = os.getenv('MT5_SERVER', '')
BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:5000')
BACKEND_API_KEY = os.getenv('BACKEND_API_KEY', '')
WEBSOCKET_HOST = os.getenv('WEBSOCKET_HOST', 'localhost')
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8765'))

# Trading configuration
MAX_RETRIES = 3
RETRY_DELAY = 5
HEARTBEAT_INTERVAL = 30


@dataclass
class TradeSignal:
    """Trade signal data structure"""
    symbol: str
    type: str  # 'BUY' or 'SELL'
    entry: float
    stop_loss: float
    take_profit: float
    lot_size: float
    comment: str
    strategy: str
    confidence: int
    timestamp: str = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now().isoformat()


@dataclass
class TradeResult:
    """Trade execution result"""
    success: bool
    ticket: int = None
    error_code: int = None
    error_message: str = None
    symbol: str = None
    type: str = None
    volume: float = None
    price: float = None
    sl: float = None
    tp: float = None
    timestamp: str = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now().isoformat()


class MT5Bridge:
    """Bridge between MT5 and Python backend"""

    def __init__(self):
        self.connected = False
        self.websocket_server = None
        self.clients = set()
        self.running = False
        self.positions = {}
        self.signals_queue = asyncio.Queue()

    async def initialize_mt5(self) -> bool:
        """Initialize MT5 connection"""
        try:
            if not mt5.initialize():
                logger.error(f"MT5 initialization failed: {mt5.last_error()}")
                return False

            logger.info("MT5 initialized successfully")

            # Login if credentials provided
            if MT5_LOGIN and MT5_PASSWORD and MT5_SERVER:
                if not mt5.login(MT5_LOGIN, MT5_PASSWORD, MT5_SERVER):
                    logger.error(f"MT5 login failed: {mt5.last_error()}")
                    return False
                logger.info(f"Logged in to MT5 account: {MT5_LOGIN}")

            # Get account info
            account_info = mt5.account_info()
            if account_info is not None:
                logger.info(f"Account Balance: ${account_info.balance}")
                logger.info(f"Account Equity: ${account_info.equity}")
                logger.info(f"Account Leverage: 1:{account_info.leverage}")

            self.connected = True
            return True

        except Exception as e:
            logger.error(f"Error initializing MT5: {e}")
            return False

    async def start_websocket_server(self):
        """Start WebSocket server for EA communication"""
        try:
            logger.info(f"Starting WebSocket server on {WEBSOCKET_HOST}:{WEBSOCKET_PORT}")

            async with websockets.serve(self.handle_client, WEBSOCKET_HOST, WEBSOCKET_PORT):
                logger.info("WebSocket server started successfully")
                await asyncio.Future()  # Run forever

        except Exception as e:
            logger.error(f"WebSocket server error: {e}")

    async def handle_client(self, websocket, path):
        """Handle individual WebSocket client connections"""
        self.clients.add(websocket)
        client_info = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        logger.info(f"Client connected: {client_info}")

        try:
            # Send welcome message
            await websocket.send(json.dumps({
                'type': 'connection',
                'status': 'connected',
                'timestamp': datetime.now().isoformat()
            }))

            async for message in websocket:
                await self.process_message(websocket, message)

        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Client disconnected: {client_info}")
        except Exception as e:
            logger.error(f"Error handling client {client_info}: {e}")
        finally:
            self.clients.remove(websocket)

    async def process_message(self, websocket, message: str):
        """Process incoming WebSocket messages"""
        try:
            data = json.loads(message)
            message_type = data.get('type')

            logger.debug(f"Received message type: {message_type}")

            if message_type == 'heartbeat':
                await websocket.send(json.dumps({
                    'type': 'heartbeat_ack',
                    'timestamp': datetime.now().isoformat()
                }))

            elif message_type == 'request_signal':
                symbol = data.get('symbol')
                signal = await self.get_signal_from_backend(symbol)
                await websocket.send(json.dumps({
                    'type': 'signal',
                    'data': asdict(signal) if signal else None
                }))

            elif message_type == 'execute_trade':
                signal_data = data.get('signal')
                result = await self.execute_trade(TradeSignal(**signal_data))
                await websocket.send(json.dumps({
                    'type': 'trade_result',
                    'data': asdict(result)
                }))

            elif message_type == 'get_positions':
                positions = await self.get_positions()
                await websocket.send(json.dumps({
                    'type': 'positions',
                    'data': positions
                }))

            elif message_type == 'get_account_info':
                account_info = await self.get_account_info()
                await websocket.send(json.dumps({
                    'type': 'account_info',
                    'data': account_info
                }))

            elif message_type == 'close_position':
                ticket = data.get('ticket')
                result = await self.close_position(ticket)
                await websocket.send(json.dumps({
                    'type': 'close_result',
                    'data': result
                }))

            else:
                logger.warning(f"Unknown message type: {message_type}")

        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON: {e}")
        except Exception as e:
            logger.error(f"Error processing message: {e}")

    async def get_signal_from_backend(self, symbol: str) -> Optional[TradeSignal]:
        """Get trading signal from backend API"""
        try:
            headers = {'Authorization': f'Bearer {BACKEND_API_KEY}'}
            response = requests.get(
                f"{BACKEND_URL}/api/signals/{symbol}",
                headers=headers,
                timeout=10
            )

            if response.status_code == 200:
                data = response.json()
                if data.get('signal'):
                    return TradeSignal(**data['signal'])

            return None

        except Exception as e:
            logger.error(f"Error getting signal from backend: {e}")
            return None

    async def execute_trade(self, signal: TradeSignal) -> TradeResult:
        """Execute trade on MT5"""
        try:
            # Prepare request
            symbol = signal.symbol
            order_type = mt5.ORDER_TYPE_BUY if signal.type == 'BUY' else mt5.ORDER_TYPE_SELL

            # Get symbol info
            symbol_info = mt5.symbol_info(symbol)
            if symbol_info is None:
                return TradeResult(
                    success=False,
                    error_message=f"Symbol {symbol} not found"
                )

            # Enable symbol if needed
            if not symbol_info.visible:
                if not mt5.symbol_select(symbol, True):
                    return TradeResult(
                        success=False,
                        error_message=f"Failed to select symbol {symbol}"
                    )

            # Prepare trade request
            point = symbol_info.point
            price = signal.entry

            request = {
                "action": mt5.TRADE_ACTION_DEAL,
                "symbol": symbol,
                "volume": signal.lot_size,
                "type": order_type,
                "price": price,
                "sl": signal.stop_loss,
                "tp": signal.take_profit,
                "deviation": 20,
                "magic": 234000,
                "comment": signal.comment,
                "type_time": mt5.ORDER_TIME_GTC,
                "type_filling": mt5.ORDER_FILLING_IOC,
            }

            # Send order
            result = mt5.order_send(request)

            if result.retcode != mt5.TRADE_RETCODE_DONE:
                return TradeResult(
                    success=False,
                    error_code=result.retcode,
                    error_message=f"Order failed: {result.comment}"
                )

            # Success
            trade_result = TradeResult(
                success=True,
                ticket=result.order,
                symbol=symbol,
                type=signal.type,
                volume=signal.lot_size,
                price=result.price,
                sl=signal.stop_loss,
                tp=signal.take_profit
            )

            logger.info(f"Trade executed: {symbol} {signal.type} {signal.lot_size} @ {result.price}")

            # Notify backend
            await self.notify_backend_trade(trade_result)

            return trade_result

        except Exception as e:
            logger.error(f"Error executing trade: {e}")
            return TradeResult(
                success=False,
                error_message=str(e)
            )

    async def get_positions(self) -> List[Dict]:
        """Get all open positions"""
        try:
            positions = mt5.positions_get()
            if positions is None:
                return []

            position_list = []
            for pos in positions:
                position_list.append({
                    'ticket': pos.ticket,
                    'symbol': pos.symbol,
                    'type': 'BUY' if pos.type == mt5.POSITION_TYPE_BUY else 'SELL',
                    'volume': pos.volume,
                    'price_open': pos.price_open,
                    'price_current': pos.price_current,
                    'sl': pos.sl,
                    'tp': pos.tp,
                    'profit': pos.profit,
                    'swap': pos.swap,
                    'comment': pos.comment
                })

            return position_list

        except Exception as e:
            logger.error(f"Error getting positions: {e}")
            return []

    async def get_account_info(self) -> Dict:
        """Get account information"""
        try:
            account_info = mt5.account_info()
            if account_info is None:
                return {}

            return {
                'login': account_info.login,
                'balance': account_info.balance,
                'equity': account_info.equity,
                'profit': account_info.profit,
                'margin': account_info.margin,
                'margin_free': account_info.margin_free,
                'margin_level': account_info.margin_level,
                'leverage': account_info.leverage,
                'currency': account_info.currency
            }

        except Exception as e:
            logger.error(f"Error getting account info: {e}")
            return {}

    async def close_position(self, ticket: int) -> Dict:
        """Close position by ticket"""
        try:
            position = mt5.positions_get(ticket=ticket)
            if not position:
                return {'success': False, 'error': 'Position not found'}

            position = position[0]

            # Prepare close request
            request = {
                "action": mt5.TRADE_ACTION_DEAL,
                "symbol": position.symbol,
                "volume": position.volume,
                "type": mt5.ORDER_TYPE_SELL if position.type == mt5.POSITION_TYPE_BUY else mt5.ORDER_TYPE_BUY,
                "position": ticket,
                "price": mt5.symbol_info_tick(position.symbol).bid if position.type == mt5.POSITION_TYPE_BUY else mt5.symbol_info_tick(position.symbol).ask,
                "deviation": 20,
                "magic": 234000,
                "comment": "Close by bridge",
                "type_time": mt5.ORDER_TIME_GTC,
                "type_filling": mt5.ORDER_FILLING_IOC,
            }

            result = mt5.order_send(request)

            if result.retcode != mt5.TRADE_RETCODE_DONE:
                return {
                    'success': False,
                    'error': result.comment
                }

            logger.info(f"Position closed: {ticket}")
            return {'success': True, 'ticket': ticket}

        except Exception as e:
            logger.error(f"Error closing position: {e}")
            return {'success': False, 'error': str(e)}

    async def notify_backend_trade(self, trade_result: TradeResult):
        """Notify backend about trade execution"""
        try:
            headers = {
                'Authorization': f'Bearer {BACKEND_API_KEY}',
                'Content-Type': 'application/json'
            }

            response = requests.post(
                f"{BACKEND_URL}/api/trades/notify",
                headers=headers,
                json=asdict(trade_result),
                timeout=10
            )

            if response.status_code == 200:
                logger.info("Backend notified successfully")
            else:
                logger.warning(f"Backend notification failed: {response.status_code}")

        except Exception as e:
            logger.error(f"Error notifying backend: {e}")

    async def monitor_positions(self):
        """Monitor and update position status"""
        while self.running:
            try:
                positions = await self.get_positions()

                # Broadcast position updates to all clients
                if self.clients:
                    message = json.dumps({
                        'type': 'position_update',
                        'data': positions,
                        'timestamp': datetime.now().isoformat()
                    })

                    await asyncio.gather(
                        *[client.send(message) for client in self.clients],
                        return_exceptions=True
                    )

                await asyncio.sleep(5)  # Update every 5 seconds

            except Exception as e:
                logger.error(f"Error monitoring positions: {e}")
                await asyncio.sleep(5)

    async def run(self):
        """Main run loop"""
        self.running = True

        # Initialize MT5
        if not await self.initialize_mt5():
            logger.error("Failed to initialize MT5. Exiting...")
            return

        logger.info("MT5 Bridge is running...")
        logger.info("Press Ctrl+C to stop")

        try:
            # Run WebSocket server and position monitor concurrently
            await asyncio.gather(
                self.start_websocket_server(),
                self.monitor_positions()
            )
        except KeyboardInterrupt:
            logger.info("Shutting down...")
        finally:
            await self.shutdown()

    async def shutdown(self):
        """Cleanup on shutdown"""
        self.running = False

        # Close all WebSocket connections
        if self.clients:
            await asyncio.gather(
                *[client.close() for client in self.clients],
                return_exceptions=True
            )

        # Shutdown MT5
        mt5.shutdown()
        logger.info("MT5 Bridge shutdown complete")


async def main():
    """Main entry point"""
    bridge = MT5Bridge()
    await bridge.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nShutdown requested... exiting")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
