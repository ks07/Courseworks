module Semantics where
import Prelude hiding (lookup)
import Data.List hiding (lookup)

data Aexp = N Integer | V Var | Add Aexp Aexp | Mult Aexp Aexp | Sub Aexp Aexp deriving (Show, Eq)
data Bexp = TRUE | FALSE | Eq Aexp Aexp | Le Aexp Aexp | Neg Bexp | And Bexp Bexp deriving (Show, Eq)
data Stm  = Ass Var Aexp | Skip | Comp Stm Stm | If Bexp Stm Stm | While Bexp Stm | Block DecV DecP Stm | Call Pname deriving (Show, Eq)

type Var = String
type Pname = String
type DecV = [(Var,Aexp)]
type DecP = [(Pname,Stm)]

type Z = Integer
type T = Bool
type State = Var -> Z
type Loc = Z
type Store = Loc -> Z
type EnvV = Var -> Loc
type EnvP = Pname -> Store -> Store

-- Finds the free variables in an arithmetic expression
fv_aexp :: Aexp -> [Var]
fv_aexp (N i) = []
fv_aexp (V v) = [ v ]
fv_aexp (Add a b) = fv_aexp (a) `union` fv_aexp (b)
fv_aexp (Mult a b) = fv_aexp (a) `union` fv_aexp (b)
fv_aexp (Sub a b) = fv_aexp (a) `union` fv_aexp (b)

-- Substitutes all occurences of a given Var inside an arithmetic expression 
-- with another arithmetic expression
subst_aexp :: Aexp -> Var -> Aexp -> Aexp
subst_aexp (N i) sub with = (N i)
subst_aexp (Add one two) sub with = (Add (subst_aexp one sub with) (subst_aexp two sub with))
subst_aexp (Mult one two) sub with = (Mult (subst_aexp one sub with) (subst_aexp two sub with))
subst_aexp (Sub one two) sub with = (Sub (subst_aexp one sub with) (subst_aexp two sub with)) 
subst_aexp (V v) sub with
    | v == sub = with
    | otherwise = (V v)

a_val :: Aexp -> State -> Z
a_val a b = 12

-- An example state for testing
testState :: State
testState "x" = 12
testState "y" = 999
testState "z" = -1
testState a = undefined
