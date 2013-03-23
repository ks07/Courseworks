module Cards where
import System.Random
import Data.Array

-- A suit type. Derives enum so we can use range notation.
data Suit = Club | Diamond | Heart | Spade
          deriving (Show, Eq, Read, Ord, Enum)

-- A rank type.
data Rank = Ace | Two | Three | Four | Five | Six | Seven |
            Eight | Nine | Ten | Jack | Queen | King
          deriving (Show, Eq, Read, Ord, Enum)

-- A card type that holds a rank and a suit
data Card = Card Rank Suit
          deriving (Show, Eq, Read, Ord)

-- Returns a human readable description of the card.
display :: Card -> String
display (Card r s) = (show r) ++ " of " ++ (show s) ++ "s"

-- Returns a list of descriptions of all the cards in the list.
displayAll :: [Card] -> [String]
displayAll cards = map display cards

-- Constant function that returns all 52 cards in order.
pack :: [Card]
pack = [Card r s | s <- [Club ..Spade], r <- [Ace ..King]]

-- Shuffles a list of cards.
shuffle :: Int -> [a] -> [a]
shuffle seed list = shuffle2 (mkStdGen seed) list []
  where
-- Inner loop function to keep track of both lists.
    shuffle2 :: StdGen -> [a] -> [a] -> [a]
    shuffle2 rand [] shuffled = shuffled
    shuffle2 rand input shuffled =
      let rnext = randomR (0, (length input) - 1) rand
          extracted = extract (fst rnext) input
      in  shuffle2 (snd rnext) (snd extracted) ((fst extracted) : shuffled)
-- Extracts the nth item from a list, where elements start at 0.
    extract :: Int -> [a] -> (a, [a])
    extract n [] = error ("Empty List")
    extract n list =
      if n >= 0 && n < (length list) then
        let right = drop n list
        in (head right, ((take n list) ++ tail right))
      else error "Tried to extract element outside of list."
