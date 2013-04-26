module Calc (main) where
import Data.Char
import Data.List
import Data.Maybe
import Numeric

stringToTokens :: String -> [String]
stringToTokens expr = words expr

precedence :: [[(String, Int)]]
precedence = [[("/", 2), ("*", 2)], [("+", 2), ("-", 2)]]

functions :: [(String, Int)]
functions = [("round", 1), ("floor", 1), ("ceil", 1), ("abs", 1)]

isFunction :: String -> Bool
isFunction func = elem func (map fst functions)

isOperator :: String -> Bool
isOperator op = elem op (map fst (foldl (++) [] precedence))

isNumeric :: String -> Bool
isNumeric [] = False
isNumeric tkn = isNumeric2 tkn False
  where
    isNumeric2 :: String -> Bool -> Bool
    isNumeric2 tkn True = all isDigit tkn 
    isNumeric2 (c : tkn) False = (c == '.' || isDigit c) && isNumeric2 tkn (c == '.')
    isNumeric2 [] dp = True

getOperatorArgs :: String -> Int
getOperatorArgs op = getOA op precedence
  where
    getOA :: String -> [[(String, Int)]] -> Int
    getOA op [] = error "Unrecognised operation."
    getOA op list =
      let sndVal = find ((op ==) . fst) (head list)
      in if isNothing sndVal then
           getOA op (tail list)
         else
           snd (fromJust sndVal)

toNum :: String -> Rational
toNum num = fst (head (readSigned readFloat num)) :: Rational

doOperation :: String -> [String] -> Rational
doOperation "+" (arg1 : arg0 : args) = toNum arg0 + toNum arg1
doOperation "-" (arg1 : arg0 : args) = toNum arg0 - toNum arg1
doOperation "*" (arg1 : arg0 : args) = toNum arg0 * toNum arg1
doOperation "/" (arg1 : arg0 : args) = toNum arg0 / toNum arg1
--doOperation "^" (arg1 : arg0 : args) = toNum arg0 ** toNum arg1
doOperation "round" (arg0 : args) = fromIntegral (round (toNum arg0))
doOperation "floor" (arg0 : args) = fromIntegral (floor (toNum arg0))
doOperation "ceil" (arg0 : args) = fromIntegral (ceiling (toNum arg0))
doOperation "abs" (arg0 : args) = abs (toNum arg0)

-- input tokens -> stack -> result
calcPostfix :: [String] -> [String] -> Rational
calcPostfix [] stack =
  if (length stack) == 1 then
    toNum (head stack)
  else
    error "Multiple values remain in stack."
calcPostfix (next : input) stack =
  if isNumeric next then
    -- push onto stack
    calcPostfix input (next : stack) 
  else
    if isOperator next || isFunction next then
      if (length stack) < (getOperatorArgs next) then
        --error "Not enough values for operation."
        error (show (getOperatorArgs next))
      else
        calcPostfix input (show (doOperation next (take (getOperatorArgs next) stack)) : (drop (getOperatorArgs next) stack))
    else
      error "Unexpected string in tokens."

-- Assuming left-assoc for now. True if op1 >= op0
checkPrec :: String -> String -> Bool
checkPrec op0 op1 = cP op0 op1 precedence
  where
    cP :: String -> String -> [[(String, Int)]] -> Bool
    cP op0 op1 [] = error "Operator does not have a precedence value."
    cP op0 op1 prec
      | fstElem op0 (head prec) && not (fstElem op1 (head prec)) = False
      | fstElem op0 (head prec) && fstElem op1 (head prec) = True
      | not (fstElem op0 (head prec)) && fstElem op1 (head prec) = True
      | not (fstElem op0 (head prec)) && not (fstElem op1 (head prec)) = cP op0 op1 (tail prec)

fstElem :: Eq a => a -> [(a, b)] -> Bool
fstElem needle [] = False
fstElem needle list = any ((needle ==) . fst) list

-- Shunting-yard algorithm http://en.wikipedia.org/wiki/Shunting_yard_algorithm
convertInfix :: [String] -> [String]
convertInfix input = convInfix input [] []
  where
    convInfix :: [String] -> [String] -> [String] -> [String]
    convInfix (next : input) queue stack
      | isNumeric next = convInfix input (next : queue) stack
      | isOperator next && (length stack) == 0 = convInfix input queue (next : stack)
      | isOperator next && isOperator (head stack) && checkPrec next (head stack) = convInfix (next : input) ((head stack) : queue) (tail stack)
      | isOperator next = convInfix input queue (next : stack)
      | next == "(" = convInfix input queue (next : stack)
      | next == ")" && (length stack) == 0 = error "Mismatched parentheses in the input equation."
      | next == ")" && (head stack) == "(" = convInfix input queue (tail stack)
      | next == ")" = convInfix (next : input) ((head stack) : queue) (tail stack)
      | otherwise = error ((show (next : input)) ++ " <=> "  ++ (show queue) ++ " <=> "  ++ (show stack))
    convInfix [] queue [] = reverse queue
    convInfix [] queue stack = convInfix [] ((head stack) : queue) (tail stack)

showAsDouble :: Rational -> String
showAsDouble val = show (fromRational val)

main :: IO()
main = do
  putStrLn "Please enter your equation in infix notation:"
  line <- getLine
  putStrLn (showAsDouble (calcPostfix (convertInfix (stringToTokens line)) []))
  putStrLn "Again? [y/n]"
  cont <- getLine
  if cont == "y" then
    main
  else
    putStrLn "end"
