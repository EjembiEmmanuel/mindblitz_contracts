use starknet::ContractAddress;

/// Player model for Dojo-based memory game
///
/// # Key
/// `username`: Unique username of the player
///
/// # Fields
/// - `owner`: Address of the player
/// - `total_games_played`: Total number of games played
/// - `total_games_completed`: Total number of games completed
/// - `total_games_won`: Total number of games won
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

/// Player statistics tracking
///
/// # Key
/// `player`: Username of the player
///
/// # Fields
/// - `total_games_played`: Total number of games played
/// - `best_score`: Best score achieved
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PlayerStats {
    #[key]
    pub player: felt252,
    pub total_games_played: u256,
    pub best_score: u256,
}

/// Username to Address mapping
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct UsernameToAddress {
    #[key]
    pub username: felt252,
    pub address: ContractAddress,
}

/// Address to Username mapping
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct AddressToUsername {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
}

pub trait PlayerTrait {
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
    use super::*;
    use starknet::contract_address::contract_address_const;

    #[test]
    #[available_gas(100000)]
    fn test_create_player() {
        let owner = contract_address_const::<0x123>();
        let username: felt252 = 'player_one';
        let player = Player {
            username, owner, total_games_played: 0, total_games_completed: 0, total_games_won: 0,
        };
        assert(player.username == username, 'username mismatch');
        assert(player.owner == owner, 'owner mismatch');
    }

    #[test]
    #[available_gas(100000)]
    fn test_username_address_mapping() {
        let owner = contract_address_const::<0x456>();
        let username: felt252 = 'unique_user';
        let username_to_address = UsernameToAddress { username, address: owner };
        let address_to_username = AddressToUsername { address: owner, username };
        assert(username_to_address.address == owner, 'address mismatch');
        assert(address_to_username.username == username, 'username mismatch');
    }
}
