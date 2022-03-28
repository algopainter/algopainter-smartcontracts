contract('AccessTesting', accounts => {
  const AccessTestingContract = artifacts.require('AccessTesting');

  it('should change the contract admin', async () => {
    const instance = await AccessTestingContract.new("5555555");

    let data = await instance.data();
    console.log(data, 'data');
    await instance.doSomethingAdmin('new text from account 0');
    data = await instance.data();
    console.log(data, 'data');
    await instance.grantRole((await instance.DEFAULT_ADMIN_ROLE()).toString(), accounts[1]);
    await instance.grantRole((await instance.CONFIGURATOR_ROLE()).toString(), accounts[1]);
    await instance.doSomethingAdmin('new text from account 1', { from: accounts[1] });
    data = await instance.data();
    console.log(data, 'data');

    await instance.revokeRole((await instance.DEFAULT_ADMIN_ROLE()).toString(), accounts[0], { from: accounts[1] });
    await instance.revokeRole((await instance.CONFIGURATOR_ROLE()).toString(), accounts[0], { from: accounts[1] });

    await instance.doSomethingAdmin('new text from account 0');
    data = await instance.data();
    console.log(data, 'data');
  });
});