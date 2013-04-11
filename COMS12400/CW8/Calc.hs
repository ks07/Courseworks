module Calc where

data Operator = ADD | SUBTRACT
     	      	deriving (Show, Eq)

data Brackets = OPEN | CLOSE
     	      	deriving (Show, Eq)

data Expression = Exp Expression Operator Expression |
     		  Num Double
		  deriving (Show, Eq)

fourplus2 :: Expression
fourplus2 = Exp (Exp (Num 2) ADD (Num 2)) (ADD) (Num 2)
