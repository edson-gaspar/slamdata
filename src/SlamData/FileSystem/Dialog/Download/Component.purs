{-
Copyright 2016 SlamData, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-}

module SlamData.FileSystem.Dialog.Download.Component
  ( comp
  , module SlamData.FileSystem.Dialog.Download.Component.State
  , module SlamData.FileSystem.Dialog.Download.Component.Query
  ) where

import SlamData.Prelude

import Control.UI.Browser (newTab)

import Data.Lens ((.~), _Right, (%~), _Left)

import DOM.Classy.Event as DOM

import Halogen as H
import Halogen.HTML as HH

import SlamData.Download.Model as D
import SlamData.Monad (Slam)
import SlamData.FileSystem.Resource (Resource)
import SlamData.FileSystem.Dialog.Download.Component.Query (Query(..))
import SlamData.FileSystem.Dialog.Download.Component.Render (render)
import SlamData.FileSystem.Dialog.Download.Component.State (State, _authHeaders,  _compress, _error, _options, _source, _targetName, checkExists, initialState, validate)

comp ∷ Resource → H.Component HH.HTML Query Unit Void Slam
comp res =
  H.component
    { initialState: const (initialState res)
    , render
    , eval
    , receiver: const Nothing
    }

eval ∷ Query ~> H.ComponentDSL State Query Void Slam
eval = case _ of
  TargetTyped s next → do
    H.modify $ validate ∘ (_targetName .~ D.validFilename s)
    pure next
  ToggleCompress next → do
    H.modify $ validate ∘ (_compress %~ not)
    pure next
  SetOutput ty next → do
    let
      options = case ty of
        D.CSV → Left ∘ either id (const D.initialCSVOptions)
        D.JSON → Right ∘ either (const D.initialJSONOptions) id
    H.modify $ validate ∘ (_options %~ options)
    pure next
  ModifyCSVOpts fn next → do
    H.modify $ validate ∘ (_options ∘ _Left %~ fn)
    pure next
  ModifyJSONOpts fn next → do
    H.modify $ validate ∘ (_options ∘ _Right %~ fn)
    pure next
  NewTab url ev next → do
    H.liftEff do
      DOM.preventDefault ev
      newTab url
    pure next
  Dismiss next →
    pure next
  SetAuthHeaders as next → do
    H.modify (_authHeaders .~ as) $> next
  PreventDefault ev next → do
    H.liftEff $ DOM.preventDefault ev
    pure next
