const Mongoose = require('mongoose');

const Schema = new Mongoose.Schema({
  tokens: { type: [Object] },
  smartcontracts: { type: [Object] },
});

module.exports = Mongoose.model('settings', Schema);