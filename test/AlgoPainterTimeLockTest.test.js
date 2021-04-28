const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterTimeLock = artifacts.require('AlgoPainterTimeLock');
var sleep = require('sleep');

contract.only('AlgoPainterToken', accounts => {
  it('should schedule a payment', async () => {
    const algop = await AlgoPainterToken.new('AlgoPainter Token', 'ALGOP');
    const timelock = await AlgoPainterTimeLock.new(algop.address);

    await algop.transfer(timelock.address, web3.utils.toWei('10000', 'ether'));

    const ref = await timelock.getNow();

    console.log('ref', ref.toString());

    await timelock.schedulePayment(accounts[1], await timelock.addSeconds(ref, 10), web3.utils.toWei('1', 'ether'));
    await timelock.schedulePayment(accounts[1], await timelock.addSeconds(ref, 20), web3.utils.toWei('2', 'ether'));
    await timelock.schedulePayment(accounts[1], await timelock.addSeconds(ref, 30), web3.utils.toWei('3', 'ether'));

    await timelock.requestPayment({ from: accounts[1] });
    let remainingAmount = await timelock.getRemainingAmount(accounts[1]);
    let balanceAfterRequestAccount1 = await algop.balanceOf(accounts[1]);
    expect(balanceAfterRequestAccount1.toString()).to.be.equal('0', 'fail to check payment #0 account #1');
    expect(remainingAmount.toString()).to.be.equal('6000000000000000000', 'fail to check remaining amount #0 account #1');

    console.log('Waiting 10s to first payment');
    sleep.sleep(10);

    await timelock.requestPayment({ from: accounts[1] });
    remainingAmount = await timelock.getRemainingAmount(accounts[1]);
    balanceAfterRequestAccount1 = await algop.balanceOf(accounts[1]);
    expect(balanceAfterRequestAccount1.toString()).to.be.equal('1000000000000000000', 'fail to check payment #1 account #1');
    expect(remainingAmount.toString()).to.be.equal('5000000000000000000', 'fail to check remaining amount #1 account #1');

    console.log('Waiting 10s to second payment');
    sleep.sleep(10);

    await timelock.requestPayment({ from: accounts[1] });

    balanceAfterRequestAccount1 = await algop.balanceOf(accounts[1]);
    remainingAmount = await timelock.getRemainingAmount(accounts[1]);
    expect(balanceAfterRequestAccount1.toString()).to.be.equal('3000000000000000000', 'fail to check payment #2 account #1');
    expect(remainingAmount.toString()).to.be.equal('3000000000000000000', 'fail to check remaining amount #2 account #1');

    console.log('Waiting 10s to third payment');
    sleep.sleep(10);

    await timelock.requestPayment({ from: accounts[1] });
    remainingAmount = await await timelock.getRemainingAmount(accounts[1]);
    balanceAfterRequestAccount1 = await algop.balanceOf(accounts[1]);
    expect(balanceAfterRequestAccount1.toString()).to.be.equal('6000000000000000000', 'fail to check payment #3 account #1');
    expect(remainingAmount.toString()).to.be.equal('0', 'fail to check remaining amount #3 account #1');
  });
});
