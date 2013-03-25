module Cards where
import System.Random
import Data.Array.ST
import Control.Monad.ST
import Control.Monad
import Data.STRef

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
shuffle seed list = fst $ shuffle' list (mkStdGen seed)

shuffle' :: [a] -> StdGen -> ([a],StdGen)
shuffle' xs gen = runST (do
        g <- newSTRef gen
        let randomRST lohi = do
              (a,s') <- liftM (randomR lohi) (readSTRef g)
              writeSTRef g s'
              return a
        ar <- newArray n xs
        xs' <- forM [1..n] $ \i -> do
                j <- randomRST (i,n)
                vi <- readArray ar i
                vj <- readArray ar j
                writeArray ar j vi
                return vj
        gen' <- readSTRef g
        return (xs',gen'))
  where
    n = length xs
    newArray :: Int -> [a] -> ST s (STArray s Int a)
    newArray n xs =  newListArray (1,n) xs

deal :: Int -> [a] -> [[a]]
deal number [] = error "Tried to deal an empty list."
deal hands list =
  if hands < 1 then
    error "Must deal to at least 1 hand."
  else
    deal2 0 hands list (take hands (cycle [[]]))
  where
    deal2 :: Int -> Int -> [a] -> [[a]] -> [[a]]
    deal2 hand hands [] dealt = dealt
    deal2 hand hands remaining dealt =
      deal2 ((hand + 1) `mod` hands) hands (tail remaining) (addnested hand (head remaining) dealt)
 
addnested :: Int -> a -> [[a]] -> [[a]]
addnested into new hands =
  let left = take into hands
      right = drop into hands
  in  left ++ [(head right) ++ [new]] ++ (tail right)
