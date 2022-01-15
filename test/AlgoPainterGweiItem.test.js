contract('AlgoPainterGweiItem', accounts => {
  const AlgoPainterToken = artifacts.require('AlgoPainterToken');
  const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');

  let algop = null;
  let instance = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    instance = await AlgoPainterGweiItem.new(algop.address, accounts[9]);
  });
  
  it('should add account[2] as a white list manager', async () => {
    const validatorRole = await instance.WHITELIST_MANAGER_ROLE();
    await instance.grantRole(validatorRole, accounts[2]);

    expect(await instance.hasRole(validatorRole, accounts[2])).to.be.equal(true, 'fail to check accounts[1] as a validator');
  });

  it('should add account[1] as a validator', async () => {
    const validatorRole = await instance.VALIDATOR_ROLE();
    await instance.grantRole(validatorRole, accounts[1]);

    expect(await instance.hasRole(validatorRole, accounts[1])).to.be.equal(true, 'fail to check accounts[1] as a validator');
  });

  it('should whitelist account #2 and #3', async () => {
    await instance.manageWhitelist([accounts[2], accounts[3]], true);
    const account2Check = await instance.isInWhitelist(accounts[2]);
    const account3Check = await instance.isInWhitelist(accounts[3]);

    expect(account2Check).to.be.true;
    expect(account3Check).to.be.true;
  });

  it('should mint a new paint', async () => {
    const owner = accounts[2];

    const amount = await instance.getCurrentAmount(0, await instance.totalSupply());
    algop.transfer(owner, amount, { from: accounts[0] });
    await algop.approve(instance.address, amount, { from: owner });

    await instance.mint(1, 'new text', false, 0, 2, amount, 'URI', { from: owner });
    const returnedTokenURI = await instance.tokenURI(1);

    expect(returnedTokenURI).to.be.equal('URI');
    expect(await instance.getName(0)).to.be.equal('Hashly Gwei');
    expect((await instance.getCollectedTokenAmount(0)).toString()).to.be.equal('300000000000000000000');
    expect((await instance.getTokenAmountToBurn(0)).toString()).to.be.equal('150000000000000000000');

    expect((await instance.getTokenStringConfigParameter(0, 1, 1)).toString()).to.be.equal('new text');
    expect(await instance.getTokenBooleanConfigParameter(0, 1, 2)).to.be.false;
    expect((await instance.getTokenUint256ConfigParameter(0, 1, 0)).toString()).to.be.equal('1');
    expect((await instance.getTokenUint256ConfigParameter(0, 1, 3)).toString()).to.be.equal('0');
    expect((await instance.getTokenUint256ConfigParameter(0, 1, 4)).toString()).to.be.equal('2');

    expect((await instance.getPIRS(0, 1)).toString()).to.be.equal('500');
  });

  it('should check next batches', async () => {

    expect((await instance.getCurrentAmount(0, 2)).toString()).to.be.equal('300000000000000000000');
    expect((await instance.getCurrentAmount(2)).toString()).to.be.equal('300000000000000000000');
    expect((await instance.getCurrentAmount(0, 456)).toString()).to.be.equal('600000000000000000000');
    expect((await instance.getCurrentAmount(456)).toString()).to.be.equal('600000000000000000000');
    expect((await instance.getCurrentAmount(0, 501)).toString()).to.be.equal('1200000000000000000000');
    expect((await instance.getCurrentAmount(501)).toString()).to.be.equal('1200000000000000000000');
    expect((await instance.getCurrentAmount(0, 703)).toString()).to.be.equal('2400000000000000000000');
    expect((await instance.getCurrentAmount(703)).toString()).to.be.equal('2400000000000000000000');
    expect((await instance.getCurrentAmount(0, 843)).toString()).to.be.equal('4800000000000000000000');
    expect((await instance.getCurrentAmount(843)).toString()).to.be.equal('4800000000000000000000');
    expect((await instance.getCurrentAmount(0, 950)).toString()).to.be.equal('9600000000000000000000');
    expect((await instance.getCurrentAmount(950)).toString()).to.be.equal('9600000000000000000000');
    expect((await instance.getCurrentAmount(0, 984)).toString()).to.be.equal('19200000000000000000000');
    expect((await instance.getCurrentAmount(984)).toString()).to.be.equal('19200000000000000000000');
    expect((await instance.getCurrentAmount(0, 986)).toString()).to.be.equal('38400000000000000000000');
    expect((await instance.getCurrentAmount(986)).toString()).to.be.equal('38400000000000000000000');
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
      expect(e.reason).to.be.equal('INVALID_VALIDATOR', 'fail to check failure');
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
      expect(e.reason).to.be.equal('INVALID_SIGNATURE', 'fail to check failure');
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
      expect(e.reason).to.be.equal('INVALID_SENDER', 'fail to check failure');
    }
  });

  it('should unlock minting for everyone after 100 units', async () => {
    const result1 = await instance.canMint(accounts[4], 10);
    const result2 = await instance.canMint(accounts[4], 101);

    expect(result1).to.be.false;
    expect(result2).to.be.true;
  });
});
