{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module BasicPolicies where

import PlutusCore.Default qualified as PLC
import PlutusTx
import PlutusTx.Lift
import PlutusTx.Prelude

import Ledger
import Ledger.Ada
import Ledger.Typed.Scripts
import Ledger.Value

tname :: TokenName
tname = error ()

key :: PubKeyHash
key = error ()

-- BLOCK1
oneAtATimePolicy :: () -> ScriptContext -> Bool
oneAtATimePolicy _ ctx =
    -- 'ownCurrencySymbol' lets us get our own hash (= currency symbol)
    -- from the context
    let ownSymbol = ownCurrencySymbol ctx
        txinfo = scriptContextTxInfo ctx
        minted = txInfoMint txinfo
    -- Here we're looking at some specific token name, which we
    -- will assume we've got from elsewhere for now.
    in case Map.lookup ownSymbol (getValue minted) of
        Nothing -> n == 0
        Just tokens -> all
            (\(tname', n') -> if tname' == tname
                then n' == 1
                else n' == 0
            )
            (Map.toList tokens)

-- We can use 'compile' to turn a minting policy into a compiled Plutus Core program,
-- just as for validator scripts. We also provide a 'wrapMintingPolicy' function
-- to handle the boilerplate.
oneAtATimeCompiled :: CompiledCode (BuiltinData -> BuiltinData -> ())
oneAtATimeCompiled = $$(compile [|| wrapMintingPolicy oneAtATimePolicy ||])
-- BLOCK2
singleSignerPolicy :: ScriptContext -> Bool
singleSignerPolicy ctx = txSignedBy (scriptContextTxInfo ctx) key
-- BLOCK3
