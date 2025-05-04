use starknet::ContractAddress;

/// Player model
///
/// # Key
///
/// `username`: Username of the player
///
/// # Fields
///
/// `owner`: Address of the player
/// `total_games_played`: Total number of games played by the player
/// `total_games_completed`: Total number of games completed by the player
/// `total_games_won`: Total number of games won by the player
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub username: felt252,
    pub owner: ContractAddress,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,
}

/// Maps a username to an address
///
/// # Key
///
/// `username`: Username of the player
///
/// # Fields
///
/// `address`: Address of the player
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct UsernameToAddress {
    #[key]
    pub username: felt252,
    pub address: ContractAddress,
}

/// Maps an address to a username
///
/// # Key
///
/// `address`: Address of the player
///
/// # Fields
///
/// `username`: Username to assign to the player
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct AddressToUsername {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
}

pub trait PlayerTrait {
    /// Creates and returns a new player
    ///
    /// # Arguments
    ///
    /// `username`: Username to assign to the new player
    /// `owner`: Account owner of player
    fn new(username: felt252, owner: ContractAddress) -> Player;
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, owner: ContractAddress) -> Player {
        Player {
            username, owner, total_games_played: 0, total_games_completed: 0, total_games_won: 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{PlayerImpl};
    use starknet::contract_address::contract_address_const;

    #[test]
    #[available_gas(100000)]
    fn test_create_new_player() {
        let owner = contract_address_const::<0x123>();
        let username: felt252 = 'test_player';

        let player = PlayerImpl::new(username, owner);
        assert(player.username == username, 'username mismatch');
        assert(player.owner == owner, 'owner mismatch');
    }

    #[test]
    #[available_gas(100000)]
    fn test_create_multiple_players_by_same_owner() {
        let owner = contract_address_const::<0x123>();
        let username_1: felt252 = 'test_player_1';
        let username_2: felt252 = 'test_player_2';

        let player_1 = PlayerImpl::new(username_1, owner);
        let player_2 = PlayerImpl::new(username_2, owner);

        assert(player_1.username == username_1, 'username_1 mismatch');
        assert(player_2.username == username_2, 'username_2 mismatch');
        assert(player_1.owner == owner, 'owner mismatch');
        assert(player_2.owner == owner, 'owner mismatch');
    }
}
