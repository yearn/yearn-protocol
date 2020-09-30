from brownie import Contract, accounts, network
from decimal import Decimal
from eth_utils import is_checksum_address
from requests import requests
from time import sleep


def get_address(msg: str) -> str:
    while True:
        addr = input(msg)
        if is_checksum_address(addr):
            return addr
        print(f"I'm sorry, but '{addr}' is not a checksummed address")


def get_gas_price(confirmation_speed: str = "fast"):
    data = requests.get("https://www.gasnow.org/api/v3/gas/price").json()
    return data["data"][confirmation_speed]


def main():
    print(f"You are using the '{network.show_active()}' network")
    dev = accounts.load("dev")
    print(f"You are using: 'dev' [{dev.address}]")
    strategy = Contract.from_explorer(get_address("Strategy to farm: "))

    while True:

        gas_price = get_gas_price()
        if strategy.tendTrigger(strategy.tend.gasEstimate() * gas_price):
            tx = strategy.tend({"from": dev, "gas_price": gas_price})
            print(f"`tend()` [{(tx.gas_used * tx.gas_price) / Decimal('1e-18')} ETH]")

        elif strategy.harvestTrigger(strategy.harvest.gasEstimate() * gas_price):
            tx = strategy.harvest({"from": dev, "gas_price": gas_price})
            print(
                f"`harvest()` [{(tx.gas_used * tx.gas_price) / Decimal('1e-18')} ETH]"
            )

        sleep(1000)
