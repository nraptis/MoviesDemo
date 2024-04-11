//
//  File.swift
//  
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation

public struct MoviesResponse {
    public let results: [Movie]
    public let page: Int
    public let total_pages: Int
    public let total_results: Int
}

extension MoviesResponse: Decodable {
    
}



/*
{
    "page": 1,
    "results": [
        {
            "adult": false,
            "backdrop_path": "/j3Z3XktmWB1VhsS8iXNcrR86PXi.jpg",
            "genre_ids": [
                28,
                878,
                12,
                14
            ],
            "id": 823464,
            "original_language": "en",
            "original_title": "Godzilla x Kong: The New Empire",
            "overview": "Following their explosive showdown, Godzilla and Kong must reunite against a colossal undiscovered threat hidden within our world, challenging their very existence – and our own.",
            "popularity": 3269.222,
            "poster_path": "/gmGK5Gw5CIGMPhOmTO0bNA9Q66c.jpg",
            "release_date": "2024-03-27",
            "title": "Godzilla x Kong: The New Empire",
            "video": false,
            "vote_average": 6.7,
            "vote_count": 504
        },
        {
            "adult": false,
            "backdrop_path": "/1XDDXPXGiI8id7MrUxK36ke7gkX.jpg",
            "genre_ids": [
                28,
                12,
                16,
                35,
                10751
            ],
            "id": 1011985,
            "original_language": "en",
            "original_title": "Kung Fu Panda 4",
            "overview": "Po is gearing up to become the spiritual leader of his Valley of Peace, but also needs someone to take his place as Dragon Warrior. As such, he will train a new kung fu practitioner for the spot and will encounter a villain called the Chameleon who conjures villains from the past.",
            "popularity": 2192.27,
            "poster_path": "/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg",
            "release_date": "2024-03-02",
            "title": "Kung Fu Panda 4",
            "video": false,
            "vote_average": 6.716,
            "vote_count": 647
        },
        {
            "adult": false,
            "backdrop_path": "/oe7mWkvYhK4PLRNAVSvonzyUXNy.jpg",
            "genre_ids": [
                28,
                53
            ],
            "id": 359410,
            "original_language": "en",
            "original_title": "Road House",
            "overview": "Ex-UFC fighter Dalton takes a job as a bouncer at a Florida Keys roadhouse, only to discover that this paradise is not all it seems.",
            "popularity": 1656.695,
            "poster_path": "/bXi6IQiQDHD00JFio5ZSZOeRSBh.jpg",
            "release_date": "2024-03-08",
            "title": "Road House",
            "video": false,
            "vote_average": 7.075,
            "vote_count": 1310
        },
        {
            "adult": false,
            "backdrop_path": "/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg",
            "genre_ids": [
                878,
                12
            ],
            "id": 693134,
            "original_language": "en",
            "original_title": "Dune: Part Two",
            "overview": "Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family. Facing a choice between the love of his life and the fate of the known universe, Paul endeavors to prevent a terrible future only he can foresee.",
            "popularity": 1933.355,
            "poster_path": "/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg",
            "release_date": "2024-02-27",
            "title": "Dune: Part Two",
            "video": false,
            "vote_average": 8.353,
            "vote_count": 2569
        },
        {
            "adult": false,
            "backdrop_path": "/9c0lHTXRqDBxeOToVzRu0GArSne.jpg",
            "genre_ids": [
                878,
                28
            ],
            "id": 935271,
            "original_language": "en",
            "original_title": "After the Pandemic",
            "overview": "Set in a post-apocalyptic world where a global airborne pandemic has wiped out 90% of the Earth's population and only the young and immune have endured as scavengers. For Ellie and Quinn, the daily challenges to stay alive are compounded when they become hunted by the merciless Stalkers.",
            "popularity": 1345.924,
            "poster_path": "/p1LbrdJ53dGfEhRopG71akfzOVu.jpg",
            "release_date": "2022-03-01",
            "title": "After the Pandemic",
            "video": false,
            "vote_average": 5.389,
            "vote_count": 27
        },
        {
            "adult": false,
            "backdrop_path": "/pwGmXVKUgKN13psUjlhC9zBcq1o.jpg",
            "genre_ids": [
                28,
                14
            ],
            "id": 634492,
            "original_language": "en",
            "original_title": "Madame Web",
            "overview": "Forced to confront revelations about her past, paramedic Cassandra Webb forges a relationship with three young women destined for powerful futures...if they can all survive a deadly present.",
            "popularity": 1179.859,
            "poster_path": "/rULWuutDcN5NvtiZi4FRPzRYWSh.jpg",
            "release_date": "2024-02-14",
            "title": "Madame Web",
            "video": false,
            "vote_average": 5.657,
            "vote_count": 1014
        },
        {
            "adult": false,
            "backdrop_path": "/wUp0bUXaveR40ikBhDgWwNTijuD.jpg",
            "genre_ids": [
                28,
                9648,
                53
            ],
            "id": 1181548,
            "original_language": "en",
            "original_title": "Heart of the Hunter",
            "overview": "A retired assassin is pulled back into action when his friend uncovers a dangerous conspiracy at the heart of the South African government.",
            "popularity": 1187.536,
            "poster_path": "/n726fdyL1dGwt15bY7Nj3XOXc4Q.jpg",
            "release_date": "2024-03-28",
            "title": "Heart of the Hunter",
            "video": false,
            "vote_average": 5.618,
            "vote_count": 38
        },
        {
            "adult": false,
            "backdrop_path": "/rKmp0vm6PNaFA0g1bzM70eyWJ6I.jpg",
            "genre_ids": [
                28
            ],
            "id": 873972,
            "original_language": "en",
            "original_title": "Hunters",
            "overview": "As John T. Wrecker continues his task of protecting a group of refugees from a virus, the threat of something new and even more dangerous grows ever closer in the form of monstrous mutants.",
            "popularity": 812.474,
            "poster_path": "/3UKlVa1CBeQkRksHV5OfFTO52qd.jpg",
            "release_date": "2021-09-13",
            "title": "Hunters",
            "video": false,
            "vote_average": 5.222,
            "vote_count": 9
        },
        {
            "adult": false,
            "backdrop_path": "/qekky2LbtT1wtbD5MDgQvjfZQ24.jpg",
            "genre_ids": [
                28,
                53
            ],
            "id": 984324,
            "original_language": "fr",
            "original_title": "Le salaire de la peur",
            "overview": "When an explosion at an oil well threatens hundreds of lives, a crack team is called upon to make a deadly desert crossing with nitroglycerine in tow.",
            "popularity": 1456.417,
            "poster_path": "/jFK2ZLQUzo9pea0jfMCHDfvWsx7.jpg",
            "release_date": "2024-03-28",
            "title": "The Wages of Fear",
            "video": false,
            "vote_average": 5.913,
            "vote_count": 119
        },
        {
            "adult": false,
            "backdrop_path": "/2KGxQFV9Wp1MshPBf8BuqWUgVAz.jpg",
            "genre_ids": [
                16,
                28,
                12,
                35,
                10751
            ],
            "id": 940551,
            "original_language": "en",
            "original_title": "Migration",
            "overview": "After a migrating duck family alights on their pond with thrilling tales of far-flung places, the Mallard family embarks on a family road trip, from New England, to New York City, to tropical Jamaica.",
            "popularity": 1008.85,
            "poster_path": "/ldfCF9RhR40mppkzmftxapaHeTo.jpg",
            "release_date": "2023-12-06",
            "title": "Migration",
            "video": false,
            "vote_average": 7.541,
            "vote_count": 1111
        },
        {
            "adult": false,
            "backdrop_path": "/deLWkOLZmBNkm8p16igfapQyqeq.jpg",
            "genre_ids": [
                14,
                28,
                12
            ],
            "id": 763215,
            "original_language": "en",
            "original_title": "Damsel",
            "overview": "A young woman's marriage to a charming prince turns into a fierce fight for survival when she's offered up as a sacrifice to a fire-breathing dragon.",
            "popularity": 787.095,
            "poster_path": "/AgHbB9DCE9aE57zkHjSmseszh6e.jpg",
            "release_date": "2024-03-07",
            "title": "Damsel",
            "video": false,
            "vote_average": 7.132,
            "vote_count": 1494
        },
        {
            "adult": false,
            "backdrop_path": "/TGsfNWkASegCfAn6ED1b08a9O6.jpg",
            "genre_ids": [
                27,
                9648,
                53
            ],
            "id": 1125311,
            "original_language": "en",
            "original_title": "Imaginary",
            "overview": "When Jessica moves back into her childhood home with her family, her youngest stepdaughter Alice develops an eerie attachment to a stuffed bear named Chauncey she finds in the basement. Alice starts playing games with Chauncey that begin playful and become increasingly sinister. As Alice’s behavior becomes more and more concerning, Jessica intervenes only to realize Chauncey is much more than the stuffed toy bear she believed him to be.",
            "popularity": 1021.698,
            "poster_path": "/9u6HEtZJdZDjPGGJq6YEuhPnoan.jpg",
            "release_date": "2024-03-06",
            "title": "Imaginary",
            "video": false,
            "vote_average": 6.081,
            "vote_count": 166
        },
        {
            "adult": false,
            "backdrop_path": "/4woSOUD0equAYzvwhWBHIJDCM88.jpg",
            "genre_ids": [
                28,
                27,
                53
            ],
            "id": 1096197,
            "original_language": "en",
            "original_title": "No Way Up",
            "overview": "Characters from different backgrounds are thrown together when the plane they're travelling on crashes into the Pacific Ocean. A nightmare fight for survival ensues with the air supply running out and dangers creeping in from all sides.",
            "popularity": 645.573,
            "poster_path": "/hu40Uxp9WtpL34jv3zyWLb5zEVY.jpg",
            "release_date": "2024-01-18",
            "title": "No Way Up",
            "video": false,
            "vote_average": 6.343,
            "vote_count": 345
        },
        {
            "adult": false,
            "backdrop_path": "/7ZP8HtgOIDaBs12krXgUIygqEsy.jpg",
            "genre_ids": [
                878,
                28,
                14,
                12
            ],
            "id": 601796,
            "original_language": "ko",
            "original_title": "외계+인 1부",
            "overview": "Gurus in the late Goryeo dynasty try to obtain a fabled, holy sword, and humans in 2022 hunt down an alien prisoner that is locked in a human's body. The two parties cross paths when a time-traveling portal opens up.",
            "popularity": 727.7,
            "poster_path": "/8QVDXDiOGHRcAD4oM6MXjE0osSj.jpg",
            "release_date": "2022-07-20",
            "title": "Alienoid",
            "video": false,
            "vote_average": 7.074,
            "vote_count": 251
        },
        {
            "adult": false,
            "backdrop_path": "/2C3CdVzINUm5Cm1lrbT2uiRstwX.jpg",
            "genre_ids": [
                28,
                14,
                10752
            ],
            "id": 856289,
            "original_language": "zh",
            "original_title": "封神第一部：朝歌风云",
            "overview": "Based on the most well-known classical fantasy novel of China, Fengshenyanyi, the trilogy is a magnificent eastern high fantasy epic that recreates the prolonged mythical wars between humans, immortals and monsters, which happened more than three thousand years ago.",
            "popularity": 797.318,
            "poster_path": "/ccJpK0rqzhQeP7Mrs2uKqObFY4L.jpg",
            "release_date": "2023-07-20",
            "title": "Creation of the Gods I: Kingdom of Storms",
            "video": false,
            "vote_average": 6.858,
            "vote_count": 179
        },
        {
            "adult": false,
            "backdrop_path": "/lzWHmYdfeFiMIY4JaMmtR7GEli3.jpg",
            "genre_ids": [
                878,
                12
            ],
            "id": 438631,
            "original_language": "en",
            "original_title": "Dune",
            "overview": "Paul Atreides, a brilliant and gifted young man born into a great destiny beyond his understanding, must travel to the most dangerous planet in the universe to ensure the future of his family and his people. As malevolent forces explode into conflict over the planet's exclusive supply of the most precious resource in existence-a commodity capable of unlocking humanity's greatest potential-only those who can conquer their fear will survive.",
            "popularity": 742.651,
            "poster_path": "/d5NXSklXo0qyIYkgV94XAgMIckC.jpg",
            "release_date": "2021-09-15",
            "title": "Dune",
            "video": false,
            "vote_average": 7.79,
            "vote_count": 11148
        },
        {
            "adult": false,
            "backdrop_path": "/inJjDhCjfhh3RtrJWBmmDqeuSYC.jpg",
            "genre_ids": [
                28,
                878,
                53
            ],
            "id": 399566,
            "original_language": "en",
            "original_title": "Godzilla vs. Kong",
            "overview": "In a time when monsters walk the Earth, humanity’s fight for its future sets Godzilla and Kong on a collision course that will see the two most powerful forces of nature on the planet collide in a spectacular battle for the ages.",
            "popularity": 552.931,
            "poster_path": "/pgqgaUx1cJb5oZQQ5v0tNARCeBp.jpg",
            "release_date": "2021-03-24",
            "title": "Godzilla vs. Kong",
            "video": false,
            "vote_average": 7.624,
            "vote_count": 9553
        },
        {
            "adult": false,
            "backdrop_path": "/bWIIWhnaoWx3FTVXv6GkYDv3djL.jpg",
            "genre_ids": [
                878,
                27,
                28
            ],
            "id": 940721,
            "original_language": "ja",
            "original_title": "ゴジラ-1.0",
            "overview": "Postwar Japan is at its lowest point when a new crisis emerges in the form of a giant monster, baptized in the horrific power of the atomic bomb.",
            "popularity": 489.282,
            "poster_path": "/hkxxMIGaiCTmrEArK7J56JTKUlB.jpg",
            "release_date": "2023-11-03",
            "title": "Godzilla Minus One",
            "video": false,
            "vote_average": 7.841,
            "vote_count": 472
        },
        {
            "adult": false,
            "backdrop_path": "/oFAukXiMPrwLpbulGmB5suEZlrm.jpg",
            "genre_ids": [
                28,
                12,
                878,
                14,
                18
            ],
            "id": 624091,
            "original_language": "id",
            "original_title": "Sri Asih",
            "overview": "Alana discover the truth about her origin: she’s not an ordinary human being. She may be the gift for humanity and become its protector as Sri Asih. Or a destruction, if she can’t control her anger.",
            "popularity": 519.189,
            "poster_path": "/wShcJSKMFg1Dy1yq7kEZuay6pLS.jpg",
            "release_date": "2022-11-17",
            "title": "Sri Asih",
            "video": false,
            "vote_average": 6.2,
            "vote_count": 73
        },
        {
            "adult": false,
            "backdrop_path": "/oBIQDKcqNxKckjugtmzpIIOgoc4.jpg",
            "genre_ids": [
                28,
                53,
                10752
            ],
            "id": 969492,
            "original_language": "en",
            "original_title": "Land of Bad",
            "overview": "When a Delta Force special ops mission goes terribly wrong, Air Force drone pilot Reaper has 48 hours to remedy what has devolved into a wild rescue operation. With no weapons and no communication other than the drone above, the ground mission suddenly becomes a full-scale battle when the team is discovered by the enemy.",
            "popularity": 484.124,
            "poster_path": "/h3jYanWMEJq6JJsCopy1h7cT2Hs.jpg",
            "release_date": "2024-01-25",
            "title": "Land of Bad",
            "video": false,
            "vote_average": 7.112,
            "vote_count": 492
        }
    ],
    "total_pages": 43488,
    "total_results": 869753
}
*/
