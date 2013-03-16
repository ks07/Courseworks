import Data.Char

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
gold (gC : guess) (sC : secret) =
  if gC == sC then 1 + gold guess secret else gold guess secret
gold guess secret = error "Length mismatch."

-- Test whether a character is contained in a string
contains :: Char -> String -> Bool
contains needle [] = False
contains needle (next : haystack) =
  if needle == next then True else contains needle haystack
