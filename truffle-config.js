module.exports = {
    networks: {
        development: {
            host: 'localhost',
            port: 8545,
            gas: 6700000,
            network_id: '*',
        },
    },
    compilers: {
        solc: {
            version: "0.5.17",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        }
    },
};