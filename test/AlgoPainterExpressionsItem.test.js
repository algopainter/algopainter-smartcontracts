const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterExpressionsItem = artifacts.require('AlgoPainterExpressionsItem');

contract('AlgoPainterExpressionsItem', accounts => {
  let instance = null;

  it('should deploy the contracts', async () => {
    instance = await AlgoPainterExpressionsItem.new(accounts[9], accounts[8]);
  });

  it('should add account[1] as a validator', async () => {
    const validatorRole = await instance.VALIDATOR_ROLE();
    await instance.grantRole(validatorRole, accounts[1]);

    expect(await instance.hasRole(validatorRole, accounts[1])).to.be.equal(true, 'fail to check accounts[1] as a validator');
  });

  it('should mint a new paint', async () => {
    const owner = accounts[2];

    const amount = await instance.getCurrentAmount(1, await instance.totalSupply());

    await instance.mint([0, 1, 9, 1, 3], amount, 'URI', { value: amount, from: owner });
    const returnedTokenURI = await instance.tokenURI(1);

    expect(returnedTokenURI).to.be.equal('URI');
    expect((await instance.getTokenUint256ConfigParameter(1, 1, 0)).toString()).to.be.equal('0');
    expect((await instance.getTokenUint256ConfigParameter(1, 1, 1)).toString()).to.be.equal('1');
    expect((await instance.getTokenUint256ConfigParameter(1, 1, 2)).toString()).to.be.equal('9');
    expect((await instance.getTokenUint256ConfigParameter(1, 1, 3)).toString()).to.be.equal('1');
    expect((await instance.getTokenUint256ConfigParameter(1, 1, 4)).toString()).to.be.equal('3');
  });

  it('should check next batches', async () => {
    expect((await instance.getCurrentAmountWithoutFee(2)).toString()).to.be.equal('100000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(300)).toString()).to.be.equal('100000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(301)).toString()).to.be.equal('200000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(500)).toString()).to.be.equal('200000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(501)).toString()).to.be.equal('300000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(600)).toString()).to.be.equal('300000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(601)).toString()).to.be.equal('400000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(700)).toString()).to.be.equal('400000000000000000');
    expect((await instance.getCurrentAmountWithoutFee(701)).toString()).to.be.equal('500000000000000000');
  });

  it('should update a token URI based on a valid signature', async () => {
    const tokenId = 1;
    const tokenURI = 'NEW_URI'
    const owner = accounts[2];

    //hashing the content used to mint a paint
    const hash = await instance.hashTokenURI(tokenId, tokenURI);

    //creating a validator signature
    const signature = await web3.eth.sign(hash, accounts[1]);
    await instance.updateTokenURI(tokenId, tokenURI, signature, {from: owner});

    const returnedTokenURI = await instance.tokenURI(1);
    expect(returnedTokenURI).to.be.equal('NEW_URI');
  });

  it('should fail to update a token URI based on an invalid validator', async () => {
    const tokenId = 1;
    const tokenURI = 'NEW_URI'
    const owner = accounts[2];

    const hash = await instance.hashTokenURI(tokenId, tokenURI);

    const signature = await web3.eth.sign(hash, accounts[3]);
    try {
      await instance.updateTokenURI(1, tokenURI, signature, {from: owner});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterExpressionsItem:INVALID_VALIDATOR', 'fail to check failure');
    }
  });

  it('should fail to update a token URI based on an invalid signature', async () => {
    const tokenURI = 'NEW_URI'
    const tokenId = 1;
    const owner = accounts[2];

    const signature = '0x0';

    try {
      await instance.updateTokenURI(tokenId, tokenURI, signature, {from: owner});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterExpressionsItem:INVALID_SIGNATURE', 'fail to check failure');
    }
  });

  it('should fail to update a token URI based on an invalid sender', async () => {
    const tokenURI = 'NEW_URI'
    const tokenId = 1;

    const signature = '0x0';

    try {
      await instance.updateTokenURI(tokenId, tokenURI, signature);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterExpressionsItem:INVALID_SENDER', 'fail to check failure');
    }
  });
});
