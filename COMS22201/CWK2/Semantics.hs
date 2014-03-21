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

-- Evaluates a given arithmetic expression in a given state
a_val :: Aexp -> State -> Z
a_val (N i) sigma = i
a_val (V v) sigma = sigma v
a_val (Add a b) sigma = (a_val a sigma) + (a_val b sigma)
a_val (Mult a b) sigma = (a_val a sigma) * (a_val b sigma)
a_val (Sub a b) sigma = (a_val a sigma) - (a_val b sigma)

-- Finds the free variables in a given boolean expression
fv_bexp :: Bexp -> [Var]
fv_bexp TRUE = []
fv_bexp FALSE = []
fv_bexp (Neg a) = fv_bexp a
fv_bexp (And a b) = (fv_bexp a) `union` (fv_bexp b)
fv_bexp (Eq a b) = (fv_aexp a) `union` (fv_aexp b)
fv_bexp (Le a b) = (fv_aexp a) `union` (fv_aexp b)

-- Substitutes all occurences of the given var in a boolean expression with
-- an arithmetic expression
subst_bexp :: Bexp -> Var -> Aexp -> Bexp
subst_bexp TRUE sub with = TRUE
subst_bexp FALSE sub with = FALSE
subst_bexp (Neg a) sub with = Neg (subst_bexp a sub with)
subst_bexp (And a b) sub with = And (subst_bexp a sub with) (subst_bexp b sub with)
subst_bexp (Eq a b) sub with = Eq (subst_aexp a sub with) (subst_aexp b sub with)
subst_bexp (Le a b) sub with = Le (subst_aexp a sub with) (subst_aexp b sub with)

-- Evaluates a given boolean expression in a given state
b_val :: Bexp -> State -> T
b_val TRUE sigma = True
b_val FALSE sigma = False
b_val (Neg a) sigma = not (b_val a sigma)
b_val (And a b) sigma = (b_val a sigma) && (b_val b sigma)
b_val (Eq a b) sigma = (a_val a sigma) == (a_val b sigma)
b_val (Le a b) sigma = (a_val a sigma) <= (a_val b sigma)

-- Conditional function that returns a function from a choice of two, using a
-- function that returns a truth value given a parameter
cond :: (a->T, a->a, a->a) -> (a->a)
cond (a, b, c) = \xs a' -> case (a a') of True -> b
                                          False -> c 

-- With thanks to Sahaj (give him 20 marks plz)
-- An example state for testing
sigma_t :: State
sigma_t "x" = 12
sigma_t "y" = 999
sigma_t "z" = -1
sigma_t v = undefined
