# Knjizalica Recommendation System

This document describes the book recommendation module implemented in the Knjizalica mobile application.

## Overview

The recommender combines two approaches described in the project application:

1. **Content-based filtering** — recommends books similar to those the user previously borrowed or searched for.
2. **Popularity-based filtering** — surfaces the most frequently borrowed titles in the library.

Both approaches only recommend books that have at least one **available copy** in the catalog.

## Data Signals

All signals are **persisted in the database** and used in scoring:

| Signal | Source table | Usage |
|--------|--------------|-------|
| Borrow history | Loans → BookCopies → Books | Preferred genres, categories, authors |
| Search history | SearchHistories | Keyword overlap with title/author/genre |
| Popularity | Loans (count by book, last 90 days) | "Most popular" section |
| Availability | BookCopies.IsAvailable | Hard filter — unavailable books excluded |

Search queries are recorded when an authenticated user searches books via GET /api/books?search=....

## Content-Based Algorithm

For each candidate book *B* (not previously borrowed by the user): score(B) = genreMatch * 3 + categoryMatch * 2 + authorMatch * 4 + searchMatch * 2

Where:

- **genreMatch** — +3 if book genre appears in user's borrowed books
- **categoryMatch** — +2 if book category appears in user's borrowed books
- **authorMatch** — +4 if book shares an author with frequently borrowed books (top 5 authors by borrow count)
- **searchMatch** — +2 if any recent search term (last 20 queries) appears in title, author name, genre, or category (case-insensitive)

Books with score > 0 are ranked descending and returned as **Featured / Personalized** recommendations.

### Explainable output

Each recommendation includes a human-readable reason string built from matched signals, for example:

> "Recommended because you enjoy Dystopia books and authors such as George Orwell."

## Popularity-Based Algorithm

popularScore(B) = COUNT(loans for book B in last 90 days)

Top *N* books by popularScore are returned in the **Most Popular** section, independent of user profile.

## API

GET /api/recommendations?limit=10
Authorization: Bearer {token}

JSON Response:

{
  "contentBased": [
    {
      "book": { "id": 1, "title": "1984", "...": "..." },
      "reason": "Because you enjoy Dystopia books"
    }
  ],
  "popular": [
    {
      "book": { "id": 2, "title": "Don Quijote", "...": "..." },
      "reason": "One of the most borrowed books in the last 90 days"
    }
  ]
}

## Mobile Integration

The home screen displays:

- **Featured** — personalized list (horizontal carousel)
- **Most Popular** — popular list

## Future Improvements

- Weight decay for older borrows
- Collaborative filtering when sufficient user overlap exists
- Exclude books with active reservations by the user
