/// Card model for single-player memory game
///
/// # Key
/// `game_id`: Game identifier
/// `card_id`: Unique ID of the card from the collection (0 to collection_size-1)
///
/// # Fields
/// - `is_clicked`: Whether this card has been clicked at least once
/// - `metadata`: Additional card metadata (e.g., image URL hash)
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Card {
    #[key]
    pub game_id: u64,
    #[key]
    pub card_id: u8,
    pub is_clicked: bool,
    pub metadata: felt252,
}

pub trait CardTrait {
    fn new(game_id: u64, card_id: u8) -> Card;
    fn update_click_status(ref self: Card, is_clicked: bool);
}

impl CardImpl of CardTrait {
    fn new(game_id: u64, card_id: u8) -> Card {
        Card { game_id, card_id, is_clicked: false, metadata: 0 }
    }

    fn update_click_status(ref self: Card, is_clicked: bool) {
        self.is_clicked = is_clicked;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[available_gas(100000)]
    fn test_create_card() {
        let game_id: u64 = 1;
        let card_id: u8 = 7;
        let is_clicked: bool = false;
        let metadata: felt252 = 'card_image_hash';

        let card = Card { game_id, card_id, is_clicked, metadata };

        assert(card.game_id == game_id, 'game_id mismatch');
        assert(card.card_id == card_id, 'card_id mismatch');
        assert(card.is_clicked == is_clicked, 'is_clicked mismatch');
    }
}
