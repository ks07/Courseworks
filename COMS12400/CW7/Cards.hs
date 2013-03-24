module Cards where
import System.Random
import Data.Array.ST
import Control.Monad.ST
import Control.Monad

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

deal :: Int -> [a] -> [[a]]
deal number [] = error "Tried to deal an empty list."
deal hands list =
  if hands < 1 then
    error "Must deal to at least 1 hand."
  else
    deal2 0 hands list (take (hands + 1) (cycle [[]]))
  where
    deal2 :: Int -> Int -> [a] -> [[a]] -> [[a]]
    deal2 hand hands remaining dealt =
      deal2 ((hand + 1) `mod` hands) hands (tail remaining) (addnested hand (head remaining) dealt)
 
addnested :: Int -> a -> [[a]] -> [[a]]
addnested into new hands =
  let left = take into hands
      right = drop into hands
  in  left ++ [new : (head right)] ++ (tail right)

-- I would try and use the Fisher-Yates shuffle, but I can't figure out
-- how to pass a mutable STArray in and out of functions in order to loop...
shufflest :: [Int] -> [Int]
shufflest list = runST $ do
  arr <- newListArray (1,(length list)) list :: ST s (STArray s Int Int)
  tmpa <- readArray arr 1
  tmpb <- readArray arr 2
  writeArray arr 1 tmpb
  writeArray arr 2 tmpa
  getElems arr
