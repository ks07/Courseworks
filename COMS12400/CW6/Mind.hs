import Data.Char
import System.IO
import System.Random

-- Checks whether a guess consists of just digits
digits :: String -> Bool 
digits [] = True
digits (c : cs) = isDigit c && digits cs

-- Checks whether a guess is valid
valid :: Int -> String -> Bool
valid len inp = if length inp == len then digits inp else False

-- Finds the gold score for a given secret and guess
gold :: String -> String -> Integer
gold [] [] = 0
gold (sC : secret) (gC : guess) =
  if gC == sC then 1 + gold secret guess else gold secret guess
gold secret guess = error "Length mismatch."

-- Test whether an element is contained in a list
contains :: (Eq a) => a -> [a] -> Bool
contains needle [] = False
contains needle (next : haystack) =
  if needle == next then True else contains needle haystack

-- Remove the first occurence of a character from a string
remove :: (Eq a) => a -> [a] -> [a]
remove needle [] = error "Haystack is empty."
remove needle haystack = remove2 needle haystack []
  where            
    remove2 :: (Eq a) => a -> [a] -> [a] -> [a]
    remove2 needle [] previous = error "Needle does not exist in haystack."
    remove2 needle (next : haystack) previous =
      if needle == next then previous ++ haystack else remove2 needle haystack (previous ++ [next])

-- Find the total score for a given secret and guess
total :: String -> String -> Integer
total secret guess =
  if (length secret) == (length guess) then total2 secret guess else error "Length mismatch." 
  where
    total2 :: String -> String -> Integer
    total2 secret (gC : guess) =
      if contains gC secret then 1 + total2 (remove gC secret) guess else total2 secret guess
    total2 secret [] = 0

-- Find the silver score for a given secret and guess
silver :: String -> String -> Integer
silver secret guess = total secret guess - gold secret guess

-- Generate a score message from the secret and guess
score :: String -> String -> String
score secret guess =
  if valid 4 guess then "Golds " ++ show (gold secret guess) ++ ", silvers " ++ show (silver secret guess) else "Bad guess"

-- Repeatedly read in a guess and respond
play :: String -> IO()
play secret = do putStr "> "
                 hFlush stdout
                 l <- getLine
                 if (l == []) || (l == secret) then return () else
                   do let guessRes = score secret l
                      putStrLn guessRes
                      hFlush stdout
                      play secret
                   
-- Generate a random secret, and print it out after playing
main :: IO()
main = do sA <- randomRIO ('0', '9')
          sB <- randomRIO ('0', '9')
          sC <- randomRIO ('0', '9')
          sD <- randomRIO ('0', '9')
          let secret = (sA : sB : sC : [sD]);
          putStrLn "Guess the 4 digit secret, press Enter to give up"
          play secret
          putStr "The secret was "
          putStrLn secret