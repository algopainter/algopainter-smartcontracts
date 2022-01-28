//This is a happy scenario testing no mocks
contract('AlgoPainterNFTCreators', accounts => {
    const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');

    const RANDOM_HEX = accounts[5];
    const RANDOM_HEX2 = accounts[6];
    const USER_ONE = accounts[1];
    const USER_TWO = accounts[2];
    const USER_THREE = accounts[3];
    const USER_FOUR = accounts[4];

    it('Should add creators and check them', async () => {
        const instance = await AlgoPainterNFTCreators.new();

        await instance.setCreator(RANDOM_HEX, USER_ONE);
        await instance.setCreator(RANDOM_HEX2, 1, USER_TWO);

        expect(USER_ONE).to.be.equal(await instance.getCreatorNotPayable(RANDOM_HEX, 0));
        expect((await instance.getCreator(RANDOM_HEX, 0)).toString()).not.be.equal(null);
        expect(USER_TWO).to.be.equal(await instance.getCreatorNotPayable(RANDOM_HEX2, 1));
        expect((await instance.getCreator(RANDOM_HEX2, 1)).toString()).not.be.equal(null);

        await instance.setCollectionCreatorByCreator(RANDOM_HEX, USER_THREE, { from: USER_ONE });
        await instance.setCollectionItemCreatorByCreator(RANDOM_HEX2, 1, USER_FOUR, { from: USER_TWO });

        expect(USER_THREE).to.be.equal(await instance.getCreatorNotPayable(RANDOM_HEX, 0));
        expect(USER_FOUR).to.be.equal(await instance.getCreatorNotPayable(RANDOM_HEX2, 1));
    });
});