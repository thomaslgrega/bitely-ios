# Bitely iOS

The iPhone app. Recipe, Shared Recipe, Private Recipe, Saved Recipe, Author,
Ingredient, Pantry Item, Match and Coverage are defined by the API and live in
[`thomaslgrega/bitelyapi`](https://github.com/thomaslgrega/bitelyapi)'s
`CONTEXT.md`. Only terms the app owns are below.

## Language

### The collection

**Cookbook**:
Everything on this device: the user's Private Recipes, the Shared Recipes they
authored, and the Saved Recipes they kept from other people. Split by
authorship, not by where a Recipe is stored.
_Avoid_: Library, collection, my recipes

### Discovery

**Today's Picks**:
The selection of Shared Recipes the app opens on, chosen by the day's date. It
makes no claim about popularity, because nothing in Bitely measures any.
_Avoid_: Popular, trending, featured, recommended

**Pantry Search**:
Searching for Recipes by the Pantry Items on hand, across both the corpus and
the Cookbook at once. The only search that works with no network and no account.
_Avoid_: Ingredient search, what-can-I-make

### Planning

**Meal Plan Day**:
A single date, holding the Recipes the user intends to cook on it under each
Meal Type. Exists only on the device; the API has no concept of a plan.
_Avoid_: Meal, planned meal, calendar entry

**Meal Type**:
Which sitting a Recipe is planned for on a Meal Plan Day: breakfast, lunch,
dinner or snack. Unrelated to a Recipe's Category — a Breakfast Recipe can be
planned for dinner.
_Avoid_: Meal slot, course

**Shopping List**:
A named set of items to buy, kept on the device. It may be written by hand or
generated from a Recipe's Ingredients, and once generated it is independent of
the Recipe it came from.
_Avoid_: Grocery list, basket
