# sonnen-poc-lib

## how-to 
* ```npm install ```
* ```npm run start-test-backend```: this will start the testbackend 
* ```npm run start-ganache```: this will start a local testchain (you can also skip this step and use your own blockchain
* ```npm run build```
* ```npm run onBoardTestAsset```

## what's included

By running ```npm run onBoardTestAsset``` it will deploy all the contracts. The addresses of all deployed contracts will be stored in the "contractConfig.json"-file located in the config folder. 

When you are also running the ui, you will have to paste the address of the OriginContractLookup-field (e.g. 0x180A291240899651ee184FA651036fE8BFC037Be) to the ui. 

After deploying the contracts, the lib will
* onboard the testusers
* onboard 2 assets (with identical properties)
* link the assets with the origin-contracts for beeing able to create certifiactes
* create a demand
* create a supply
* create an agreement
* create a meterreading for asset 1, resulting in the creating of a certificate
