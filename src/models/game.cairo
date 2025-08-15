use starknet::get_block_timestamp;

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Active,
    Ended,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum DifficultyLevel {
    Easy,
    Medium,
    Hard,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub id: felt252,
    pub current_val: u64,
}

/// Game model for single-player memory game (click without repeating)
///
/// # Key
/// `game_id`: Unique identifier for the game instance
///
/// # Fields
/// - `player`: Username of the player
/// - `score`: Current score (number of unique cards clicked)
/// - `best_score`: Best score achieved by this player
/// - `status`: Game status (Active or Ended)
/// - `start_time`: When the game started
/// - `end_time`: When the game ended (0 if not finished)
/// - `board_size`: Number of cards shown in the current game (e.g., 4, 5, 6)
/// - `difficulty_level`: Difficulty level (Easy, Medium, Hard)
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u64,
    pub player: felt252,
    pub score: u256,
    pub best_score: u256,
    pub status: GameStatus,
    pub start_time: u64,
    pub end_time: u64,
    pub board_size: u8,
    pub collection_size: u8,
    pub difficulty_level: DifficultyLevel,
}

pub trait GameTrait {
    fn new(game_id: u64, player: felt252, difficulty_level: DifficultyLevel) -> Game;
    fn update_best_score(ref self: Game);
    fn restart(ref self: Game);
    fn end_game(ref self: Game);
}

impl GameImpl of GameTrait {
    fn new(game_id: u64, player: felt252, difficulty_level: DifficultyLevel) -> Game {
        // Set board size and collection size based on difficulty
        let board_size = match difficulty_level {
            DifficultyLevel::Easy => 4,
            DifficultyLevel::Medium => 6,
            DifficultyLevel::Hard => 8,
        };

        Game {
            game_id,
            player,
            score: 0,
            best_score: 0,
            status: GameStatus::Active,
            start_time: get_block_timestamp(),
            end_time: 0,
            board_size,
            collection_size: 20,
            difficulty_level,
        }
    }

    fn update_best_score(ref self: Game) {
        self.best_score = self.score;
    }

    fn restart(ref self: Game) {
        self.score = 0;
        self.status = GameStatus::Active;
        self.start_time = get_block_timestamp();
        self.end_time = 0;
    }

    fn end_game(ref self: Game) {
        self.status = GameStatus::Ended;
        self.end_time = get_block_timestamp();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use starknet::testing::set_block_timestamp;

    #[test]
    fn test_create_game() {
        let game_id: u64 = 1;
        let player: felt252 = 'alice';
        let difficulty_level: DifficultyLevel = DifficultyLevel::Medium;
        let timestamp = 1754579281;

        set_block_timestamp(timestamp);

        let game = GameTrait::new(game_id, player, difficulty_level);

        assert(game.game_id == game_id, 'game_id match');
        assert(game.player == player, 'player match');
        assert(game.score == 0, 'score 0');
        assert(game.best_score == 0, 'best_score 0');
        assert(game.status == GameStatus::Active, 'status active');
        assert(game.board_size == 6, 'medium 6 cards');
        assert(game.collection_size == 20, 'collection 20');
        assert(game.difficulty_level == difficulty_level, 'difficulty match');
        assert(game.start_time > 0, 'start_time set');
        assert(game.end_time == 0, 'end_time 0');
    }

    #[test]
    #[available_gas(100000)]
    fn test_difficulty_levels() {
        let game_id: u64 = 1;
        let player: felt252 = 'alice';
        let timestamp = 1754579281;

        set_block_timestamp(timestamp);

        // Test Easy difficulty
        let easy_game = GameTrait::new(game_id, player, DifficultyLevel::Easy);
        assert(easy_game.board_size == 4, 'easy 4 cards');

        // Test Medium difficulty
        let medium_game = GameTrait::new(game_id + 1, player, DifficultyLevel::Medium);
        assert(medium_game.board_size == 6, 'medium 6 cards');

        // Test Hard difficulty
        let hard_game = GameTrait::new(game_id + 2, player, DifficultyLevel::Hard);
        assert(hard_game.board_size == 8, 'hard 8 cards');
    }

    #[test]
    #[available_gas(100000)]
    fn test_update_best_score() {
        let mut game = GameTrait::new(1, 'player', DifficultyLevel::Easy);

        // Initially best_score should be 0
        assert(game.best_score == 0, 'best_score 0');

        // Update score to a new value
        game.score = 10;
        GameTrait::update_best_score(ref game);
        assert(game.best_score == 10, 'best_score 10');

        // Update score to a higher value
        game.score = 25;
        GameTrait::update_best_score(ref game);
        assert(game.best_score == 25, 'best_score 25');

        // Update score to a lower value (should still update)
        game.score = 15;
        GameTrait::update_best_score(ref game);
        assert(game.best_score == 15, 'best_score 15');
    }

    #[test]
    #[available_gas(100000)]
    fn test_restart_game() {
        let mut game = GameTrait::new(1, 'player', DifficultyLevel::Medium);

        let timestamp = 1754579281;

        set_block_timestamp(timestamp);

        // Set some game state
        game.score = 15;
        game.best_score = 20;
        game.end_time = 1000;

        // Restart the game
        GameTrait::restart(ref game);

        // Verify restart behavior
        assert(game.score == 0, 'score reset');
        assert(game.best_score == 20, 'best_score unchanged');
        assert(game.status == GameStatus::Active, 'status active');
        assert(game.end_time == 0, 'end_time reset');
        assert(game.start_time > 0, 'start_time updated');
    }

    #[test]
    #[available_gas(100000)]
    fn test_end_game() {
        let mut game = GameTrait::new(1, 'player', DifficultyLevel::Hard);

        let timestamp = 1754579281;

        set_block_timestamp(timestamp);

        // Initially game should be active
        assert(game.status == GameStatus::Active, 'game active');
        assert(game.end_time == 0, 'end_time 0');

        // End the game
        GameTrait::end_game(ref game);

        // Verify end game behavior
        assert(game.status == GameStatus::Ended, 'status ended');
        assert(game.end_time > 0, 'end_time set');
    }

    #[test]
    #[available_gas(100000)]
    fn test_game_lifecycle() {
        let mut game = GameTrait::new(1, 'player', DifficultyLevel::Easy);

        // Initial state
        assert(game.status == GameStatus::Active, 'game active');
        assert(game.score == 0, 'score 0');

        // Play the game (update score)
        game.score = 5;
        GameTrait::update_best_score(ref game);
        assert(game.best_score == 5, 'best_score 5');

        // Continue playing
        game.score = 8;
        GameTrait::update_best_score(ref game);
        assert(game.best_score == 8, 'best_score 8');

        // End the game
        GameTrait::end_game(ref game);
        assert(game.status == GameStatus::Ended, 'game ended');

        // Restart the game
        GameTrait::restart(ref game);
        assert(game.status == GameStatus::Active, 'game active');
        assert(game.score == 0, 'score reset');
        assert(game.best_score == 8, 'best_score preserved');
    }
}
