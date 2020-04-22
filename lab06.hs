import Data.Char

data Func = Func String Expr

-- the recursive type
data Expr = 
    Str String | Const Double
  | UnaryOp Char Expr
  | BinaryOp Char Expr Expr
  | Let String Expr Expr
  | If Expr Expr Expr
  | ApplyFunc Func Expr
  
-- polymorphic functions
eval _ (Const a) = a
eval env (Str s) = eval env (Const (getValue s env))
eval env (BinaryOp op a b) = getBopFromChar op (eval env a) (eval env b)
eval env (UnaryOp op a) = getUopFromChar op $ eval env a
eval env (Let var expr1 expr2) = eval (insert (var, eval env expr1) env) expr2
eval env (If cond expr1 elseExpr2)
  | eval env cond /= 0 = eval env expr1
  | otherwise = eval env elseExpr2
eval env (ApplyFunc (Func arg expr) argVal) =  eval env (Let arg argVal expr)

--wrapper call to eval with empty env
ev expr = eval [] expr

getUopFromChar c = case c of
  '!' -> (\x -> if x /= 0 then 0 else 1)
  '-' -> getBopFromChar c 0.0 -- (-n = 0 - n)
  
getBopFromChar c = case c of
  '+' -> (+)
  '-' -> (-)
  '*' -> (*)
  '/' -> (/)
  '<' -> (\a b -> if a < b then 1 else 0)
  '>' -> (\a b -> if a > b then 1 else 0)
  _ -> error $ c:" unknown operator"
   
-- insert a new key-value tuple in the environment
-- or replace the value if the key already exist
insert tuple [] = [tuple]
insert tuple (x:xs) 
  | fst x == fst tuple = tuple:xs
  | otherwise = x:(insert tuple xs)

-- get the value associated to the given key
-- in a map access fashion, representing the local
-- environment to the expressions 
-- If the key doesn't exist, display an error message
-- although this kind of error should be handled before evaluation
-- of expression in syntaxic analysis, here just for
-- debug purpose
getValue key [] = error ("variable " ++ key ++ " not in scope")
getValue key (x:xs) 
  | fst x == key = snd x
  | otherwise = getValue key xs

-- polymorphic display
instance Show Expr where
  show (Const a) = show a
  show (Str s) = s
  show (BinaryOp c a b) = show a ++ c:show b
  show (UnaryOp c a) = c:'(':show a ++ ")"
  show (Let var expr1 expr2) = "(let " ++ var ++ '=':show expr1 ++ " in " ++ show expr2 ++ ")"
  show (If cond expr1 elseExpr2) = "cond : (" ++ show cond ++ " ? " ++ show expr1 ++ " : " ++ show elseExpr2 ++ ")"
  show (ApplyFunc (Func arg expr) argVal) = "(func (" ++ arg ++ "=" ++ show argVal ++ ") = " ++ show expr ++ ")"
  
expr0 = Let "toto" (Const 4) (BinaryOp '+' (Str "toto") (Str "toto"))
expr1 = Let "toto" (Const 7) (BinaryOp '*' (Str "toto" )((BinaryOp '*' (Const 2) expr0)))
expr2 = BinaryOp '*' (Let "toto" (Const 1) (BinaryOp '+' (Str "toto") (Const 1))) (Str "toto")

expr3 = If (BinaryOp '>' (Str "toto") (Const 10)) (BinaryOp '+' (Const 4) (Const 5)) (Str "toto")
expr4 = Let "toto" (Const 12) expr3

cond = BinaryOp '<' (Str "n") (Const 1)
fact = Func "n" (If (UnaryOp '!' cond) (BinaryOp '*' (Str "n") (ApplyFunc fact (BinaryOp '-' (Str "n") (Const 1)))) (Const 1))              
incr = Func "n" (BinaryOp '+' (Str "n") (Const 1))

res1 = ApplyFunc incr (Const 4)

res2 = ApplyFunc fact (Const 4)

res3 = Let "n" (Const 6) (BinaryOp '+' res1 (Str "n"))

res4 = ApplyFunc incr (UnaryOp '-' (Const 4))