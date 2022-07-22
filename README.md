# Roll NFT

## Project Description

Raffle roll protocol for NFT assets, designed to bring gambling aspect to NFT trades and exchanges.

Application allows to create raffles with existing NFT assets easy way. Whether it's an NFT Avatar, Game asset or Digital art.
And play it among the participants who have tickets for this particular draw event. More draw entries - higher chances.

Active draws could be found on dashboard and filtered by NFT collections and / or categories.
On profile page available list of current, upcoming and past raffles it's management and watch lists of favorite collections and raffle hosts.

For NFT holders it provides additional way to trade, with opportunity for asset being valued higher then market.
From other perspective allows participants to compete for prizes with lower expenses comparing to market asset's value.

The goal is to attract additional attention to NFTs and increase the volume of trade and exchange transactions. And achieve more precise and stable price values as consequence with higher demand for useful or popular NFTs.

Project developed in terms of [hackfs2022 hackathon](https://fs.ethglobal.com/).

## Technologies used

Roll NFT would be implemented as ERC1155 smart contract.
Tableland will be used to reach data mutability and multi-chain presence (NFTPort).
Detailed dashboard will be provided by TheGraph. With option for Covalent being used for profile page and favorites.
To generate frontend would be used [Hyperdapp](https://hyperdapp.dev/).
Valist to deliver smart contract's and application's versions.
To simplify Raffle roll creation will be used Composits (DataModels) from Ceramic (Glaze).


## Main application contract's logic
#### Used for:

#### Create a NFT roll (Returns raffleRollID)
Send NFT asset (prize) into protocol ( prize pool of a rool).
Set price for a roll Entry (ticket price).
Set limits for amount of Entry (tickets amount): a. UpperEntryLimit ( 0 is unlimited). b. LowerEntryLimit ( 0 is possible value).
Set deadlineTimestamp to play a roll.
Creates raffleRollID NFT collection.
Roll metadata would be updated.
a. raffleRollID.host sender.
b. raffleRollID.RollSucceed to False.
c. raffleRollID.RollFinished to False.
d. raffleRollID.UpperEntryLimit.
e. raffleRollID.LowerEntryLimit.
f. raffleRollID.deadlineTimestamp.
g. raffleRollID.winner[] is empty.
h. raffleRollID.HostReward is 0.
i. raffleRollID.RewardToClaim is False.
j. raffleRollID.PrizeAvailable is False.
k. raffleRollID.nextTicketID is 0.
l. raffleRollID.PrizeToWithdraw is False.
Return raffleRollID.

#### Participate (Buy entry tickets) in a NFT roll (Returns ticketID)
Set raffleRollID.
Set amount of tickets.
Set tokenContract to pay with.
Set tokenAmount to send into protocol. Goes to prize pool of a raffleRollID.rollHost.
Mints ticket (erc1155 NFT token from raffleRollID NFT collection). Visible on profile dashboard.
Roll metadata would be updated:
a. raffleRollID.nextTicketID is increased.
b. raffleRollID.HostReward is increased by tokenAmount.
Return ticketID.

#### Raffle Roll conditions:
All entries are sold. If UpperLimit set, then Roll will be played once all tickets (in amount of UpperEntryLimit value) are sold.
Deadline passed.
a. If deadlineTimestamp set, and LowerEntryLimit is 0 and UpperLimit is 0. Then Roll will be played at moment of deadlineTimestamp.
b. If deadlineTimestamp set, and LowerEntryLimit is 0 and UpperLimit is not 0. Then Roll will be played if UpperLimit is reached at moment of deadlineTimestamp.
c. If deadlineTimestamp set, and LowerEntryLimit is not 0. Then Roll will be played if LowerEntryLimit is reached at moment of deadlineTimestamp.

#### Raffle Roll execution. Choosing winner:
1. On success:
Roll metadata would be updated. a. Winner ticketID's will be set to raffleRollID.winners[]. b. RollSucceed will be set "True" to raffleRollID.RollSucceed. c. RollFinished will be set "True" to raffleRollID.RollFinished. d. RewardToClaim will be set "True" to raffleRollID.RewardToClaim e. Set raffleRollID.HostReward to EntriesSold * EntryPrice. f. PrizeAvailable will be set "True" to raffleRollID.PrizeAvailable
Winner ticket owner will be able to Claim it's reward.
Host of raffleRollID can claim his reward ( HostReward = EntriesSold * EntryPrice ). Or there is an option to airdrop reward (erc20 token) through SuperFluid stream protocol.
Probably:

Update winner ticketID metadata. ticketID.winner set to True. Possible only if we can restrict anyone except contract to update that metadata.
2. On failure:
Roll metadata would be updated. a. RollSucceed will be set "False" to raffleRollID.RollSucceed. b. RollFinished will be set "True" to raffleRollID.RollFinished. c. Set raffleRollID.HostReward to 0. d. raffleRollID.PrizeToWithdraw is True.

#### Claim prize from a NFT roll.
Set raffleRollID.
Set ticketID.
Check if owner of ticketID
Check if ticketID is a winner raffleRollID.winners[].
Burn entry NFT (ticketID).
Recieve NFT asset (prize) from protocol.
Update Roll metadata: a. PrizeAvailable will be set "False" to raffleRollID.PrizeAvailable.

#### Claim host reward from a NFT roll.
Set raffleRollID.
Check if raffleRollID.host.
Check that raffleRollID.RewardToClaim is True
Check that raffleRollID.HostReward more then 0.
Recieve erc20 assets ( HostReward = EntriesSold * EntryPrice ) from protocol.
Update Roll metadata: a. RewardToClaim will be set "False" to raffleRollID.RewardToClaim. b. HostReward will be set 0 to raffleRollID.HostReward.

#### Withdraw NFT from a NFT roll.
Set raffleRollID.
Check that raffleRollID.RollSucceed is "False".
Check that raffleRollID.RollFinished is "True".
Check if raffleRollID.host
Check that raffleRollID.PrizeToWithdraw is True.
Recieve NFT asset (prize) from protocol.
Update Roll metadata: a. Set raffleRollID.PrizeToWithdraw is False.