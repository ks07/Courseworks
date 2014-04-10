module Semantics where
import Prelude hiding (lookup)
import Data.List hiding (lookup)

-- TO ENABLE DEBUGGING IN STATEMENTS: Uncomment the following import, the alternative Stm, and the relevant lines in s_*.
-- Use the debugging by wrapping any statement, s, in your AST in (Dbg "some_var" s).
-- import Debug.Trace

data Aexp = N Integer | V Var | Add Aexp Aexp | Mult Aexp Aexp | Sub Aexp Aexp deriving (Show, Eq)
data Bexp = TRUE | FALSE | Eq Aexp Aexp | Le Aexp Aexp | Neg Bexp | And Bexp Bexp deriving (Show, Eq)
data Stm  = Ass Var Aexp | Skip | Comp Stm Stm | If Bexp Stm Stm | While Bexp Stm | Block DecV DecP Stm | Call Pname deriving (Show, Eq)
-- Alternative Stm to add debugging support.
-- data Stm  = Ass Var Aexp | Skip | Comp Stm Stm | If Bexp Stm Stm | While Bexp Stm | Block DecV DecP Stm | Call Pname | Dbg Var Stm deriving (Show, Eq)

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
cond (boolFunc, trueBody, falseBody) sigma
  | (boolFunc sigma) = trueBody sigma
  | otherwise        = falseBody sigma

-- 'Functional Update', takes a function (e.g. state), value, and key and returns a new function
update :: Eq a => (a->b) -> b -> a -> (a->b)
update s v x y
  | x == y    = v
  | otherwise = (s y)

-- Least fixpoint operator
fix :: ((a->a) -> (a->a)) -> (a->a)
fix ff = ff (fix ff)

-- While language semantic function
s_ds :: Stm -> State -> State
s_ds Skip         sigma = sigma
s_ds (Ass v a)    sigma = (update sigma (a_val a sigma) v)
s_ds (Comp s1 s2) sigma = ((s_ds s2) . (s_ds s1)) sigma
s_ds (If b s1 s2) sigma = cond ((b_val b), (s_ds s1), (s_ds s2)) sigma
s_ds (While b s1) sigma = fix ff sigma
  where ff g = cond ((b_val b), g.(s_ds s1), id)
-- Uncomment to enable debugging for s_ds (see above)
-- s_ds (Dbg v s1)   sigma = trace (v ++ " = " ++ show (sigma v)) (s_ds s1 sigma)

-- AST for factorial program in While
p :: Stm
p = (Comp (Ass "x" (N 5)) (Comp (Ass "y" (N 1)) (While (Neg (Eq (V "x") (N 1))) (Comp (Ass "y" (Mult (V "y") (V "x"))) (Ass "x" (Sub (V "x") (N 1)))) ) ))

-- Initial state for p
sigma_p :: State
sigma_p v = undefined

-- Final values of x and y after evaluating p in state sigma_p
p' :: (Z,Z)
p' = (sigma_final "x", sigma_final "y")
  where sigma_final = s_ds p sigma_p

-- Test function to make sure p' hasn't broken and is still giving the expected results
test_p' :: Bool
test_p' = p' == (1,120)

--------------------------------------------------------------
--------------------------- Part 2 ---------------------------
--------------------------------------------------------------

-- Returns the successor of a location
new :: Loc -> Loc
new = succ

-- Constant next location of 0
next :: Loc
next = 0

-- Lookup function. We now have variable environments, 'EnvV's that map variables to locations,
-- and Stores that map locations to values. This function combines the two to make a state.
lookup :: EnvV -> Store -> State
lookup ve st = st . ve

-- Variable environment update. Takes some changes to make to the state and the current state (env/loc).
d_v_ds :: DecV -> (EnvV, Store) -> (EnvV, Store)
d_v_ds [] (ve, st) = (ve, st)
d_v_ds ((x, a) : remaining) (ve, st) = d_v_ds remaining (( update ve l x ), ( update ( update st v l ) (new l) next )) -- TODO: Can we do this with composition?
  where l = st next
        v = a_val a (lookup ve st)

-- Procedure environment update.
d_p_ds :: DecP -> EnvV -> EnvP -> EnvP
d_p_ds [] ve pe = pe
d_p_ds ((p, body) : remaining) ve pe = d_p_ds remaining ve (update pe (fix ff) p)
  where ff g = s_static body ve (update pe g p)

-- A new semantic function for Proc with static scoping
s_static :: Stm -> EnvV -> EnvP -> Store -> Store
s_static Skip         ve pe st = st
s_static (Ass v a)    ve pe st = update st ( a_val a (lookup ve st) ) ( ve v )
s_static (Comp s1 s2) ve pe st = ((s_static s2 ve pe) . (s_static s1 ve pe)) st
s_static (If b s1 s2) ve pe st = cond ( (b_val b) . (lookup ve), (s_static s1 ve pe), (s_static s2 ve pe) ) st
s_static (While b s1) ve pe st = fix ff st
  where ff g = cond ( (b_val b) . (lookup ve), g . (s_static s1 ve pe), id )
s_static (Call p)     ve pe st = pe p st
s_static (Block d_v d_p s1) ve pe st = s_static s1 ve' pe' st'
  where (ve', st') = d_v_ds d_v (ve, st)
        pe' = d_p_ds d_p ve' pe
-- Uncomment to enable debugging for s_static (see above)
-- s_static (Dbg v s1)      ve pe st = trace (v ++ " = " ++ show ((lookup ve st) v)) (s_static s1 ve pe st)

-- Minimal store mapping only next
t :: Store
t 0 = 1
t l = undefined

-- AST for factorial program in Proc
q :: Stm
-- begin
q = (Block 
--   var x:=5;
        [("x", (N 5)),
--   var y:=1;
        ("y", (N 1))] 
--   proc fac is
        [("fac", 
--     begin
          (Block 
--       var z:=x;
           [("z", (V "x"))] []
--       if x=1 then
           (If (Eq (V "x") (N 1)) 
--         skip
            Skip
--       else
            (Comp 
--         x:=x-1;
             ((Ass "x") (Sub (V "x") (N 1))) 
--         call fac;
             (Comp (Call "fac")
--         y:=z*y
             (Ass "y" (Mult (V "z") (V "y"))))) )
--     end
         ))] 
--   call fac
        (Call "fac")
-- end
    )

-- Empty EnvV for q
env_v_q :: EnvV
env_v_q = undefined

-- Empty EnvP for q
env_p_q :: EnvP
env_p_q = undefined

-- Final store values after evaluating q on t using s_static (from location 0 to n)
q' :: [Z]
q' = [ st_q loc | loc <- [0..end_loc] ]
  where end_loc = (st_q 0) - 1
        st_q = s_static q env_v_q env_p_q t

-- Test function to make sure q' hasn't broken and is still giving the expected results
test_q' :: Bool
test_q' = q' == [8,1,120,5,4,3,2,1]

--------------------------------------------------------------
--------------------------- Part 3 ---------------------------
--------------------------------------------------------------

-- AST for part 3 program
r :: Stm
-- begin
r = (Block 
--   var x:=0;
     [("x", (N 0))] 
--   proc p is x:=x*2;
     [("p", (Ass "x" (Mult (V "x") (N 2)))), 
--   proc q is call p;
      ("q", (Call "p"))] 
--   begin
     (Block 
--     var x:=5;
      [("x", (N 5))] 
--     proc p is x:=x+1;
      [("p", (Ass "x" (Add (V "x") (N 1))))]
--     call q
      (Call "q")
--   end
     )
-- end
    )

-- Final values of outer and inner x variables after evaluating r using static scoping
r1 :: (Z,Z)
r1 = (ox, ix)
  where ox = st_r 1
        ix = st_r 2
        st_r = s_static r env_v_q env_p_q t

-- Test function for r1
test_r1 :: Bool
test_r1 = r1 == (0,5)

-- Final values of outer and inner x variables after evaluating r using mixed scoping
r2 :: (Z,Z)
r2 = (0,10)

-- Final values of outer and inner x variables after evaluating r using dynamic scoping
r3 :: (Z,Z)
r3 = (0,6)

-- Alternative EnvP type for mixed scoping. See Semantics with Applications by Nielson p60
type EnvP' = Pname -> Stm

-- Alternative d_p_ds for mixed scoping ==> upd_p!
d_p_ds_m :: DecP -> EnvP' -> EnvP'
d_p_ds_m [] pe = pe
d_p_ds_m ((p, body) : remaining) pe = d_p_ds_m remaining (update pe body p)
--  where ff g = s_mixed body ve (update pe g p)

-- Semantic function for Proc with dynamic scoping for variables
s_mixed :: Stm -> EnvV -> EnvP' -> Store -> Store
s_mixed Skip         ve pe st = st
s_mixed (Ass v a)    ve pe st = update st ( a_val a (lookup ve st) ) ( ve v )
s_mixed (Comp s1 s2) ve pe st = ((s_mixed s2 ve pe) . (s_mixed s1 ve pe)) st
s_mixed (If b s1 s2) ve pe st = cond ( (b_val b) . (lookup ve), (s_mixed s1 ve pe), (s_mixed s2 ve pe) ) st
s_mixed (While b s1) ve pe st = fix ff st
  where ff g = cond ( (b_val b) . (lookup ve), g . (s_mixed s1 ve pe), id )
s_mixed (Call p)     ve pe st = s_mixed (pe p) ve pe st
s_mixed (Block d_v d_p s1) ve pe st = s_mixed s1 ve' pe' st'
  where (ve', st') = d_v_ds d_v (ve, st)
        pe' = d_p_ds_m d_p pe
-- Uncomment to enable debugging for s_mixed (see above)
-- s_mixed (Dbg v s1)      ve pe st = trace (v ++ " = " ++ show ((lookup ve st) v)) (s_mixed s1 ve pe st)

-- Alternative EnvP type for dynamic scoping. See Semantics with Applications by Nielson p60
type EnvP'' = Pname -> Stm

-- Alternative d_p_ds for dynamic scoping ==> upd_p!
d_p_ds_m :: DecP -> EnvP'' -> EnvP''
d_p_ds_m [] pe = pe
d_p_ds_m ((p, body) : remaining) pe = d_p_ds_m remaining (update pe body p)

-- Semantic function for Proc with dynamic scoping for variables
s_dynamic :: Stm -> EnvV -> EnvP'' -> Store -> Store
s_dynamic Skip         ve pe st = st
s_dynamic (Ass v a)    ve pe st = update st ( a_val a (lookup ve st) ) ( ve v )
s_dynamic (Comp s1 s2) ve pe st = ((s_dynamic s2 ve pe) . (s_dynamic s1 ve pe)) st
s_dynamic (If b s1 s2) ve pe st = cond ( (b_val b) . (lookup ve), (s_dynamic s1 ve pe), (s_dynamic s2 ve pe) ) st
s_dynamic (While b s1) ve pe st = fix ff st
  where ff g = cond ( (b_val b) . (lookup ve), g . (s_dynamic s1 ve pe), id )
s_dynamic (Call p)     ve pe st = s_dynamic (pe p) ve pe st
s_dynamic (Block d_v d_p s1) ve pe st = s_dynamic s1 ve' pe' st'
  where (ve', st') = d_v_ds d_v (ve, st)
        pe' = d_p_ds_m d_p pe
-- Uncomment to enable debugging for s_dynamic (see above)
-- s_dynamic (Dbg v s1)      ve pe st = trace (v ++ " = " ++ show ((lookup ve st) v)) (s_dynamic s1 ve pe st)

-- Run all tests
run_tests :: Bool
run_tests = test_p' && test_q' && test_r1
