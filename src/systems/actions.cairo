use starknet::ContractAddress;

use mindblitz::models::game::DifficultyLevel;


#[starknet::interface]
pub trait IActions<T> {
    // Player management
    fn register_player(ref self: T, username: felt252);

    // Game management
    fn create_new_game_id(ref self: T) -> u64;
    fn create_game(ref self: T, difficulty_level: DifficultyLevel);
    fn restart_game(ref self: T, game_id: u64);
    fn end_game(ref self: T, game_id: u64);

    // Card management
    fn click_card(ref self: T, game_id: u64, card_id: u8);

    // Getters
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn get_address_from_username(self: @T, username: felt252) -> ContractAddress;
}


#[dojo::contract]
pub mod actions {
    use super::{IActions, DifficultyLevel};
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const,
    };

    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;

    use mindblitz::models::card::{Card, CardTrait};
    use mindblitz::models::player::{Player, PlayerTrait, UsernameToAddress, AddressToUsername};
    use mindblitz::models::game::{Game, GameTrait, GameStatus, GameCounter};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCreated {
        #[key]
        pub game_id: u64,
        pub owner: ContractAddress,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameRestarted {
        #[key]
        pub game_id: u64,
        pub owner: ContractAddress,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameEnded {
        #[key]
        pub game_id: u64,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub owner: ContractAddress,
        pub timestamp: u64,
    }


    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct CardClicked {
        #[key]
        pub card_id: u8,
        #[key]
        pub game_id: u64,
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[abi(embed_v0)]
    impl MindBlitzImpl of IActions<ContractState> {
        // Player management
        fn register_player(ref self: ContractState, username: felt252) {
            let mut world = self.world_default();

            let caller = get_caller_address();

            let zero_address = contract_address_const::<0x0>();

            // Validate username
            assert(username != 0, 'USERNAME CANNOT BE ZERO');

            let existing_player: Player = world.read_model(username);

            // Ensure player username is unique
            assert(existing_player.owner == zero_address, 'USERNAME ALREADY TAKEN');

            // Ensure player cannot update username by calling this function
            let existing_username = self.get_username_from_address(caller);

            assert(existing_username == 0, 'USERNAME ALREADY CREATED');

            let player = PlayerTrait::new(username, caller);

            let username_to_address = UsernameToAddress { username, address: caller };
            let address_to_username = AddressToUsername { address: caller, username };

            world.write_model(@player);
            world.write_model(@username_to_address);
            world.write_model(@address_to_username);

            world
                .emit_event(
                    @PlayerCreated { username, owner: caller, timestamp: get_block_timestamp() },
                );
        }

        // Game management
        fn create_new_game_id(ref self: ContractState) -> u64 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }

        fn create_game(ref self: ContractState, difficulty_level: DifficultyLevel) {
            let mut world = self.world_default();

            let caller = get_caller_address();
            let username = self.get_username_from_address(caller);
            assert(username != 0, 'PLAYER NOT REGISTERED');

            let game_id = self.create_new_game_id();

            let game = GameTrait::new(game_id, username, difficulty_level);

            // Initializa cards
            let mut i: u8 = 0;
            loop {
                if i >= game.collection_size {
                    break;
                }
                let card = CardTrait::new(game_id, i);
                world.write_model(@card);
                i += 1;
            };

            world.write_model(@game);

            world
                .emit_event(
                    @GameCreated { game_id, owner: caller, timestamp: get_block_timestamp() },
                );
        }

        fn restart_game(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();

            let caller = get_caller_address();

            let username = self.get_username_from_address(caller);
            assert(username != 0, 'PLAYER NOT REGISTERED');

            let mut game: Game = world.read_model(game_id);
            assert(game.player == username, 'PLAYER DOES NOT OWN THE GAME');

            GameTrait::restart(ref game);

            let mut i: u8 = 0;
            loop {
                if i >= game.collection_size {
                    break;
                }

                let mut card: Card = world.read_model((game_id, i));

                let is_clicked = card.is_clicked;
                if is_clicked {
                    CardTrait::update_click_status(ref card, false);
                    world.write_model(@card);
                }

                i += 1;
            };

            world.write_model(@game);

            world
                .emit_event(
                    @GameRestarted { game_id, owner: caller, timestamp: get_block_timestamp() },
                );
        }

        // Card management
        fn click_card(ref self: ContractState, game_id: u64, card_id: u8) {
            let mut world = self.world_default();

            let caller = get_caller_address();

            let username = self.get_username_from_address(caller);
            assert(username != 0, 'PLAYER NOT REGISTERED');

            let mut game: Game = world.read_model(game_id);
            assert(game.status == GameStatus::Active, 'GAME NOT ACTIVE');
            assert(game.player == username, 'PLAYER DOES NOT OWN THE GAME');

            let mut card: Card = world.read_model((game_id, card_id));

            // Check if this is a repeat click (game over condition)
            let is_clicked = card.is_clicked;

            if !is_clicked {
                // First time clicking this card
                // Update card
                CardTrait::update_click_status(ref card, true);
                world.write_model(@card);

                game.score += 1;

                let has_won = GameTrait::check_win_status(ref game);

                if (has_won) {
                    if game.score > game.best_score {
                        GameTrait::update_best_score(ref game);
                    }

                    GameTrait::end_game(ref game);

                    let mut player: Player = world.read_model(game.player);
                    player.total_games_played += 1;
                    player.total_games_won += 1;

                    world.write_model(@player);

                    world.emit_event(@GameEnded { game_id, timestamp: get_block_timestamp() });
                }

                world.write_model(@game);
            } else {
                // Update best score if needed
                if game.score > game.best_score {
                    GameTrait::update_best_score(ref game);
                }

                GameTrait::end_game(ref game);

                let mut player: Player = world.read_model(game.player);
                player.total_games_played += 1;
                player.total_games_lost += 1;

                world.write_model(@player);

                world.write_model(@game);

                world.emit_event(@GameEnded { game_id, timestamp: get_block_timestamp() });
            }

            world
                .emit_event(
                    @CardClicked {
                        card_id, game_id, player: caller, timestamp: get_block_timestamp(),
                    },
                );
        }

        fn get_username_from_address(self: @ContractState, address: ContractAddress) -> felt252 {
            let mut world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }

        fn get_address_from_username(self: @ContractState, username: felt252) -> ContractAddress {
            let mut world = self.world_default();

            let username_map: UsernameToAddress = world.read_model(username);

            username_map.address
        }


        // Game actions
        fn end_game(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();

            let caller = get_caller_address();

            let username = self.get_username_from_address(caller);
            assert(username != 0, 'PLAYER NOT REGISTERED');

            // Update game
            let mut game: Game = world.read_model(game_id);

            assert(game.player == username, 'PLAYER DOES NOT OWN THE GAME');

            // Update best score if needed
            if game.score > game.best_score {
                GameTrait::update_best_score(ref game);
            }

            GameTrait::end_game(ref game);

            // Update player stats
            let mut player: Player = world.read_model(game.player);
            player.total_games_played += 1;

            world.write_model(@player);

            world.write_model(@game);

            world.emit_event(@GameEnded { game_id, timestamp: get_block_timestamp() });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"mindblitz")
        }
    }
}
