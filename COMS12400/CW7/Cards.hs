module Cards (main) where
import System.Random
import Data.Array.ST
import Control.Monad.ST
import Control.Monad
import Data.STRef
import System.IO

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
-- The dollar operator treats everything after it as if it were in brackets
shuffle seed list = fst $ shuffle' list (mkStdGen seed)

-- This is taken from: http://www.haskell.org/haskellwiki/Random_shuffle#Imperative_algorithm
-- This implements the Fisher-Yates shuffle (O(n)) using Haskell's ST Monad. A Monad allows imperative code
-- within the functional language. IO has it's own monad. The ST Monad is used to gain access to
-- mutable variables and arrays, while appearing like a standard functional function to the outside world.
shuffle' :: [a] -> StdGen -> ([a],StdGen)
shuffle' xs gen = runST (do
        -- We create a STRef from the generator. An STRef is a mutable value made from a regular value.
        g <- newSTRef gen
	-- We define a function within the monad that returns the next value from the rng.
        let randomRST lohi = do
	      -- liftM creates a monad from a regular function, in this case randomR
              (a,s') <- liftM (randomR lohi) (readSTRef g)
	      -- We have to update the rng so we get a different number next time. writeSTRef assigns the new rng.
              writeSTRef g s'
	      -- return brings a standard value into a monad type. This allows us to use the return value of randomRST in the monad code.
              return a
        ar <- newArray n xs
        -- xs' is the new list after shuffling. It is assigned the result of forM, which loops through the
	-- list in the first argument and runs the function given as the second. In this case, we use an
	-- anonymous function, denoted by the \ operator.
        xs' <- forM [1..n] $ \i -> do
                j <- randomRST (i,n)
		-- Read the current and a random element into temporary variables and swap the first.
                vi <- readArray ar i
                vj <- readArray ar j
                writeArray ar j vi
		-- Return the element that we displaced. forM records each value returned from the given function.
		-- This means that forM incrementally builds the resultant list from the displaced elements.
                return vj
	-- Finally, return the shuffled list and the new StdGen in case we want to get more values elsewhere.
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

main :: IO()
main = do
  putStrLn "Starting a new singleplayer blackjack game."
  s <- randomRIO (1,9999999)
  let seed = s
  let deck = shuffle seed pack
  play False (False,False) (deal 2 (take 2 deck)) (drop 2 deck)
  return ()

play :: Bool -> (Bool,Bool) -> [[Card]] -> [Card] -> IO()
play bankturn stuck hands deck = do
  if bankturn then do
    if (fst stuck) then do
      if (snd stuck) then do
        if (getHandTotal (hands!!0)) > (getHandTotal (hands!!1)) then do
          putStrLn "You lose!"
        else do
          putStrLn "You win!"
      else do
        play False stuck hands deck
    else do
      let bank = getHandTotal (hands!!0)
      -- Simple AI
      if bank < 17 then do
        let newHands = addnested 0 (head deck) hands
	let newDeck = tail deck
	let newbank = getHandTotal (newHands!!0)
	if newbank > 21 then do
	  putStrLn "Bank is bust - you win!"
	else do
	  play False stuck newHands newDeck
      else do
        let newstuck = (True,(snd stuck))
        play False newstuck hands deck
  else do
    if (snd stuck) then do
      play True stuck hands deck
    else do
      putStr "Your hand: "
      putStrLn (show (displayAll (hands!!1)))
      putStr "Bank: "
      putStrLn (display (head (hands!!0)))
      putStrLn "(H)it or (S)tick?"
      hFlush stdout
      l <- getLine
      if (l == "H") then do
        let newHands = addnested 1 (head deck) hands
        let newDeck = tail deck
	putStrLn (show (displayAll (newHands!!1)))
	let total = getHandTotal (newHands!!1)
        putStr "Your hand is worth: "
	putStrLn (show total)
	if (total > 21) then do
	  putStrLn "Bust - You lose!"
	else do
	  play True stuck newHands newDeck
      else do
        if (l == "S") then do
          let newstuck = ((fst stuck),True)
          play True newstuck hands deck
	else do
          error "Incorrect command."
  return ()

getHandTotal :: [Card] -> Int
getHandTotal hand = handtot hand 0
  where
    handtot :: [Card] -> Int -> Int
    handtot [] total = total
    handtot (c : hand) total =
      if (rank c) /= Ace then
        handtot hand ((fromEnum (rank c)) + total + 1)
      else
        if (total + 11) > 21 then
	  handtot hand (total + 1)
	else
	  handtot hand (total + 11)

rank :: Card -> Rank
rank (Card rank suit) = rank