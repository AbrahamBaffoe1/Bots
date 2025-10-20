const express = require('express');
const router = express.Router();
const licenseController = require('../controllers/licenseController');
const { auth } = require('../middleware/auth');

// License routes
router.get('/', auth, licenseController.getUserLicenses);
router.post('/validate', auth, licenseController.validateLicense);
router.post('/', auth, licenseController.createLicense);
router.put('/:id/revoke', auth, licenseController.revokeLicense);

module.exports = router;
