module Calc (main) where
import Data.Char
import Data.List
import Data.Maybe
import Data.Ratio
import Numeric
import Debug.Trace

stringToTokens :: String -> [String]
stringToTokens expr = words expr

infixToTokens :: String -> String
infixToTokens expr = infixToTokens2 (stripSpaces expr) Nothing
  where
    infixToTokens2 :: [Char] -> Maybe Char -> String
    infixToTokens2 [] prev = ""
    infixToTokens2 (next : expr) prev
      | isDigit next || next == '.' = (next : (infixToTokens2 expr (Just next)))
      | next == '-' && isOperator [(fromMaybe '+' prev)] = ' ' : next : (infixToTokens2 expr (Just next))
      | next == '(' || next == ')' || isOperator [next] = ' ' : next : ' ' : (infixToTokens2 expr (Just next))
      | otherwise = error "fail"

stripSpaces :: String -> String
stripSpaces str = filter (not . isSpace) str
  
precedence :: [[(String, Int)]]
precedence = [[("^", 2)], [("/", 2), ("*", 2)], [("+", 2), ("-", 2)]]

functions :: [(String, Int)]
functions = [("round", 1), ("floor", 1), ("ceil", 1), ("abs", 1), ("dbg", 1), ("sqrt", 1)]

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
           
getFunctionArgs :: String -> Int
getFunctionArgs func =                              
  let sndVal = find ((func ==) . fst) functions
  in if isNothing sndVal then
       error "Unrecognised function."
     else
       snd (fromJust sndVal)

toNum :: String -> Rational
toNum num = fst (head (readSigned readFloat num)) :: Rational

doOperation :: String -> [Rational] -> Rational
doOperation "+" (arg1 : arg0 : args) = arg0 + arg1
doOperation "-" (arg1 : arg0 : args) = arg0 - arg1
doOperation "*" (arg1 : arg0 : args) = arg0 * arg1
doOperation "/" (arg1 : arg0 : args) = arg0 / arg1
doOperation "^" (arg1 : arg0 : args) = rationalPow arg0 arg1
doOperation "sqrt" (arg0 : args) = rationalSqrt arg0
doOperation "round" (arg0 : args) = fromIntegral (round arg0)
doOperation "floor" (arg0 : args) = fromIntegral (floor arg0)
doOperation "ceil" (arg0 : args) = fromIntegral (ceiling arg0)
doOperation "abs" (arg0 : args) =
  if arg0 < 0 then 
    arg0 * (-1 :: Rational)
  else
    arg0
doOperation "dbg" (arg0 : args) = error $ show arg0

rationalPow :: Rational -> Rational -> Rational
rationalPow val power
  | power == 0 = 1
  | power == 0.5 = rationalSqrt val
  | power == 1 = val
  | (denominator power) == 1 && power < 0 = 1 / (rationalPow val (power * (-1)))
  | (denominator power) == 1 = val * (rationalPow val (power - 1))
  | otherwise = toRational ((fromRational val) ** (fromRational power))
--  | otherwise = error "Fractional powers are not supported currently." 

rationalSqrt :: Rational -> Rational
rationalSqrt square = newtonRaphsonSqrt square (roughSqrt square) 0.000000001 10
  where
    newtonRaphsonSqrt :: Rational -> Rational -> Rational -> Integer -> Rational
    newtonRaphsonSqrt square approx epsilon maxIter =
      if maxIter < 0 then
        approx
      else
        if (2 * approx) < epsilon then
          error (show maxIter)
          --newtonRaphsonIter square approx
        else
          trace (show maxIter) (newtonRaphsonIter square (newtonRaphsonSqrt square approx epsilon (maxIter - 1)))
    newtonRaphsonIter :: Rational -> Rational -> Rational
    newtonRaphsonIter square approx = approx - (approx * approx - square) / (2 * approx)
    roughSqrt :: Rational -> Rational
    roughSqrt square
      | square >= 1 =
        let d = length (show (floor square))
        in if odd d then
             (2 :: Rational) * (fromIntegral (10 ^ ((d - 1) `div` 2)))
           else
             (6 :: Rational) * (fromIntegral (10 ^ ((d - 2) `div` 2)))
      | square < 1 =
        let d = (-1) * (countImmZ (showAsDouble square) False)
        in if odd d then
             (2 :: Rational) * (toRational (10.0 ^^ ((d - 1) `div` 2)))
           else
             (6 :: Rational) * (toRational (10.0 ^^ ((d - 2) `div` 2)))             
      where
        countImmZ :: String -> Bool -> Integer
        countImmZ (dig : digr) seenDP =
          if seenDP then
            if dig == '0' then
              1 + (countImmZ digr seenDP)
            else
              0
          else
            if dig == '.' then
              countImmZ digr True
            else
              countImmZ digr False
              
  
-- input tokens -> stack -> result
calcPostfix :: [String] -> [Rational] -> Rational
calcPostfix [] stack =
  if (length stack) == 1 then
    head stack
  else
    error "Multiple values remain in stack."
calcPostfix (next : input) stack =
  if isNumeric next then
    -- push onto stack
    calcPostfix input ((toNum next) : stack) 
  else
    if isOperator next || isFunction next then
      let argCount = if isOperator next then
                       getOperatorArgs next
                     else
                       getFunctionArgs next
      in if (length stack) < argCount then
           error "Not enough values for operation."
         else
           calcPostfix input (doOperation next (take argCount stack) : (drop argCount stack))
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
      | isNumeric next = trace "1" $ convInfix input (next : queue) stack
      | isFunction next = trace "2" $ convInfix input queue (next : stack)
      | next == "," && (length stack) == 0 = error "Mismatched parentheses in the input equation." 
      | next == "," && (head stack) == "(" = trace "3" $ convInfix input queue stack
      | next == "," = trace "4" $ convInfix (next : input) ((head stack) : queue) (tail stack)
      | isOperator next && (length stack) == 0 = trace "5" $ convInfix input queue (next : stack)
      | isOperator next && isOperator (head stack) && checkPrec next (head stack) = trace "6" $ convInfix (next : input) ((head stack) : queue) (tail stack)
      | isOperator next = trace "7" $ convInfix input queue (next : stack)
      | next == "(" = trace "8" $ convInfix input queue (next : stack)
      | next == ")" && (length stack) == 0 = error "Mismatched parentheses in the input equation."
      | next == ")" && (head stack) == "(" && (length stack) > 1 && isFunction (head (tail stack)) = trace "9" $ convInfix input ((head (tail stack)) : queue) (tail (tail stack))
      | next == ")" && (head stack) == "(" = trace "10" $ convInfix input queue (tail stack)
      | next == ")" = trace ("11 " ++ (show queue)) $ convInfix (next : input) ((head stack) : queue) (tail stack)
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
