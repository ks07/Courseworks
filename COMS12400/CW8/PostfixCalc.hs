module Calc (main) where
import Data.Char

stringToTokens :: String -> [String]
stringToTokens expr = words expr

precedence :: [[String]]
precedence = [["/", "*"], ["+", "-"]]

isOperator :: String -> Bool
isOperator op = any (elem op) precedence

isNumeric :: String -> Bool
isNumeric [] = False
isNumeric tkn = isNumeric2 tkn False
  where
    isNumeric2 :: String -> Bool -> Bool
    isNumeric2 tkn True = all isDigit tkn 
    isNumeric2 (c : tkn) False = (c == '.' || isDigit c) && isNumeric2 tkn (c == '.')
    isNumeric2 [] dp = True

getOperatorArgs :: String -> Int
getOperatorArgs "+" = 2
getOperatorArgs "-" = 2
getOperatorArgs "*" = 2
getOperatorArgs "/" = 2
getOperatorArgs op = error "Unrecognised operator."

toNum :: String -> Double
toNum num = read num :: Double

doOperation :: String -> [String] -> Double
doOperation "+" (arg1 : arg0 : args) = toNum arg0 + toNum arg1
doOperation "-" (arg1 : arg0 : args) = toNum arg0 - toNum arg1
doOperation "*" (arg1 : arg0 : args) = toNum arg0 * toNum arg1
doOperation "/" (arg1 : arg0 : args) = toNum arg0 / toNum arg1

-- input tokens -> stack -> result
calcPostfix :: [String] -> [String] -> Double
calcPostfix [] stack =
  if (length stack) == 1 then
    read (head stack) :: Double
  else
    error "Multiple values remain in stack."
calcPostfix (next : input) stack =
  if isNumeric next then
    -- push onto stack
    calcPostfix input (next : stack) 
  else
    if isOperator next then
      if (length stack) < (getOperatorArgs next) then
        error "Not enough values for operation."
      else
        calcPostfix input (show (doOperation next (take (getOperatorArgs next) stack)) :  (drop (getOperatorArgs next) stack))
    else
      error "Unexpected string in tokens."

-- Assuming left-assoc for now. True if op1 >= op0
checkPrec :: String -> String -> Bool
checkPrec op0 op1 = cP op0 op1 precedence
  where
    cP :: String -> String -> [[String]] -> Bool
    cP op0 op1 prec
      | elem op0 (head prec) && notElem op1 (head prec) = False
      | elem op0 (head prec) && elem op1 (head prec) = True
      | notElem op0 (head prec) && elem op1 (head prec) = True
      | notElem op0 (head prec) && notElem op1 (head prec) = cP op0 op1 (tail prec)

convertInfix :: [String] -> [String]
convertInfix input = convInfix input [] []
  where
    convInfix :: [String] -> [String] -> [String] -> [String]
    convInfix (next : input) queue stack
      | isNumeric next = convInfix input (next : queue) stack
      | isOperator next && (length stack) == 0 = convInfix input queue (next : stack)
      | isOperator next && isOperator (head stack) && checkPrec next (head stack) = convInfix (next : input) ((head stack) : queue) (tail stack)
      | isOperator next && isOperator (head stack) && not (checkPrec next (head stack)) = convInfix input queue (next : stack)
    convInfix [] queue [] = reverse queue
    convInfix [] queue stack = convInfix [] ((head stack) : queue) (tail stack)

main :: IO()
main = do
  putStrLn "Please enter your equation in infix notation:"
  line <- getLine
  putStrLn (show (calcPostfix (convertInfix (stringToTokens line)) []))
  putStrLn "Again? [y/n]"
  cont <- getLine
  if cont == "y" then
    main
  else
    putStrLn "end"
