//
//  The API speaks snake_case and the app speaks camelCase. Every mismatch between the
//  two is silent: a wrong CodingKey drops a field instead of failing. These tests pin
//  the wire format down. See commit 804c8d6, where `total_cook_time` went missing.
//

import Foundation
import Testing
@testable import Bitely

@Suite("Wire format")
struct WireFormatTests {

    // MARK: - Decoding

    @Test("RecipeSummaryDTO decodes the snake_case summary payload")
    func decodesRecipeSummary() throws {
        let json = Data(#"""
        {
          "id": "r1",
          "name": "Roast Chicken",
          "category": "Chicken",
          "thumbnail_url": "https://example.com/a.jpg",
          "calories": 640,
          "total_cook_time": 95
        }
        """#.utf8)

        let summary = try JSONDecoder().decode(RecipeSummaryDTO.self, from: json)

        #expect(summary.id == "r1")
        #expect(summary.name == "Roast Chicken")
        #expect(summary.category == .chicken)
        #expect(summary.thumbnailUrl == "https://example.com/a.jpg")
        #expect(summary.calories == 640)
        #expect(summary.totalCookTime == 95)
    }

    @Test("RecipeSummaryDTO tolerates null optionals")
    func decodesRecipeSummaryWithNulls() throws {
        let json = Data(#"""
        {
          "id": "r1",
          "name": "Mystery",
          "category": "Other",
          "thumbnail_url": null,
          "calories": null,
          "total_cook_time": null
        }
        """#.utf8)

        let summary = try JSONDecoder().decode(RecipeSummaryDTO.self, from: json)

        #expect(summary.thumbnailUrl == nil)
        #expect(summary.calories == nil)
        #expect(summary.totalCookTime == nil)
    }

    @Test("RecipeDetailDTO decodes user_id, ingredients and cook time")
    func decodesRecipeDetail() throws {
        let json = Data(#"""
        {
          "id": "r1",
          "user_id": "u9",
          "name": "Carbonara",
          "category": "Pasta",
          "instructions": "Boil water.",
          "thumbnail_url": "https://example.com/b.jpg",
          "ingredients": [
            { "id": "i1", "name": "Spaghetti", "measurement": "200 g" },
            { "id": "i2", "name": "Guanciale", "measurement": "100 g" }
          ],
          "calories": 780,
          "total_cook_time": 25
        }
        """#.utf8)

        let detail = try JSONDecoder().decode(RecipeDetailDTO.self, from: json)

        #expect(detail.id == "r1")
        #expect(detail.userId == "u9")
        #expect(detail.category == .pasta)
        #expect(detail.instructions == "Boil water.")
        #expect(detail.totalCookTime == 25)
        #expect(detail.ingredients.count == 2)
        #expect(detail.ingredients.first?.name == "Spaghetti")
        #expect(detail.ingredients.first?.measurement == "200 g")
    }

    @Test("RecipeDetailDTO survives an encode/decode round trip")
    func recipeDetailRoundTrips() throws {
        let original = RecipeDetailDTO(
            id: "r1",
            userId: "u9",
            name: "Carbonara",
            category: .pasta,
            instructions: "Boil water.",
            thumbnailUrl: "https://example.com/b.jpg",
            ingredients: [IngredientDTO(id: "i1", name: "Spaghetti", measurement: "200 g")],
            calories: 780,
            totalCookTime: 25
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecipeDetailDTO.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.userId == original.userId)
        #expect(decoded.name == original.name)
        #expect(decoded.category == original.category)
        #expect(decoded.instructions == original.instructions)
        #expect(decoded.thumbnailUrl == original.thumbnailUrl)
        #expect(decoded.calories == original.calories)
        #expect(decoded.totalCookTime == original.totalCookTime)
        #expect(decoded.ingredients.map(\.name) == original.ingredients.map(\.name))
    }

    @Test("RecipeDetailDTO encodes the snake_case keys the API expects")
    func recipeDetailEncodesSnakeCase() throws {
        let detail = RecipeDetailDTO(
            id: "r1",
            userId: "u9",
            name: "Carbonara",
            category: .pasta,
            instructions: nil,
            thumbnailUrl: "https://example.com/b.jpg",
            ingredients: [],
            calories: 780,
            totalCookTime: 25
        )

        let object = try encodeToObject(detail)

        #expect(object["user_id"] as? String == "u9")
        #expect(object["thumbnail_url"] as? String == "https://example.com/b.jpg")
        #expect(object["total_cook_time"] as? Int == 25)
    }

    @Test("AuthResponse decodes access_token and the nested user")
    func decodesAuthResponse() throws {
        let json = Data(#"""
        {
          "access_token": "jwt-token",
          "user": {
            "id": "u1",
            "email": "cook@example.com",
            "first_name": "Ada",
            "last_name": "Lovelace"
          }
        }
        """#.utf8)

        let response = try JSONDecoder().decode(AuthResponse.self, from: json)

        #expect(response.accessToken == "jwt-token")
        #expect(response.user.id == "u1")
        #expect(response.user.email == "cook@example.com")
        #expect(response.user.firstName == "Ada")
        #expect(response.user.lastName == "Lovelace")
    }

    @Test("User decodes when the optional name fields are absent")
    func decodesSparseUser() throws {
        let json = Data(#"{ "id": "u1" }"#.utf8)

        let user = try JSONDecoder().decode(User.self, from: json)

        #expect(user.id == "u1")
        #expect(user.email == nil)
        #expect(user.firstName == nil)
        #expect(user.lastName == nil)
    }

    // MARK: - Encoding the create request

    @Test("CreateRecipeRequest encodes total_cook_time and thumbnail_url")
    func createRequestEncodesSnakeCase() throws {
        let request = CreateRecipeRequest(
            name: "Carbonara",
            category: .pasta,
            instructions: "Boil water.",
            thumbnailUrl: "https://example.com/b.jpg",
            ingredients: [CreateIngredientRequest(name: "Spaghetti", measurement: "200 g")],
            calories: 780,
            totalCookTime: 25
        )

        let object = try encodeToObject(request)

        #expect(object["name"] as? String == "Carbonara")
        #expect(object["category"] as? String == "Pasta")
        #expect(object["instructions"] as? String == "Boil water.")
        #expect(object["thumbnail_url"] as? String == "https://example.com/b.jpg")
        #expect(object["calories"] as? Int == 780)
        #expect(object["total_cook_time"] as? Int == 25)

        let ingredients = try #require(object["ingredients"] as? [[String: Any]])
        #expect(ingredients.count == 1)
        #expect(ingredients[0]["name"] as? String == "Spaghetti")
        #expect(ingredients[0]["measurement"] as? String == "200 g")
    }

    @Test("CreateRecipeRequest uses no camelCase keys the API would ignore")
    func createRequestHasNoCamelCaseKeys() throws {
        let request = CreateRecipeRequest(
            name: "Carbonara",
            category: .pasta,
            instructions: nil,
            thumbnailUrl: nil,
            ingredients: [],
            calories: nil,
            totalCookTime: 25
        )

        let object = try encodeToObject(request)

        #expect(object["totalCookTime"] == nil)
        #expect(object["thumbnailUrl"] == nil)
    }

    // MARK: - Categories

    @Test("FoodCategory decodes every raw value the API can send", arguments: FoodCategory.allCases)
    func decodesEveryCategory(category: FoodCategory) throws {
        let json = Data("\"\(category.rawValue)\"".utf8)

        let decoded = try JSONDecoder().decode(FoodCategory.self, from: json)

        #expect(decoded == category)
    }

    @Test("an unrecognized category decodes as Other rather than throwing")
    func unknownCategoryDecodesAsOther() throws {
        let json = Data("\"Fusion\"".utf8)

        let decoded = try JSONDecoder().decode(FoodCategory.self, from: json)

        #expect(decoded == .other)
    }

    @Test("a category still encodes its own raw value, so sharing round-trips",
          arguments: FoodCategory.allCases)
    func categoryEncodesRawValue(category: FoodCategory) throws {
        let data = try JSONEncoder().encode(category)

        #expect(String(decoding: data, as: UTF8.self) == "\"\(category.rawValue)\"")
    }

    @Test("one unrecognized category does not fail the rest of the response")
    func unknownCategoryDoesNotFailSiblingRecipes() throws {
        let json = Data(#"""
        [
          { "id": "r1", "name": "Roast Chicken", "category": "Chicken",
            "thumbnail_url": null, "calories": null, "total_cook_time": null },
          { "id": "r2", "name": "Fusion Bowl", "category": "Fusion",
            "thumbnail_url": null, "calories": null, "total_cook_time": null },
          { "id": "r3", "name": "Carbonara", "category": "Pasta",
            "thumbnail_url": null, "calories": null, "total_cook_time": null }
        ]
        """#.utf8)

        let summaries = try JSONDecoder().decode([RecipeSummaryDTO].self, from: json)

        #expect(summaries.map(\.id) == ["r1", "r2", "r3"])
        #expect(summaries.map(\.category) == [.chicken, .other, .pasta])
    }

    @Test("an unrecognized category on a recipe detail decodes as Other")
    func unknownCategoryOnDetailDecodesAsOther() throws {
        let json = Data(#"""
        {
          "id": "r1",
          "user_id": "u9",
          "name": "Fusion Bowl",
          "category": "Fusion",
          "instructions": null,
          "thumbnail_url": null,
          "ingredients": [],
          "calories": null,
          "total_cook_time": null
        }
        """#.utf8)

        let detail = try JSONDecoder().decode(RecipeDetailDTO.self, from: json)

        #expect(detail.category == .other)
    }

    // MARK: - Helpers

    private func encodeToObject(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }
}
