module challenge::marketplace;

use challenge::hero::Hero;
use sui::coin::{Self, Coin};
use sui::event;
use sui::sui::SUI;

// ========= ERRORS =========

const EInvalidPayment: u64 = 1;

// ========= STRUCTS =========

public struct ListHero has key, store {
    id: UID,
    nft: Hero,
    price: u64,
    seller: address,
}

// ========= CAPABILITIES =========

public struct AdminCap has key, store {
    id: UID,
}

// ========= EVENTS =========

public struct HeroListed has copy, drop {
    list_hero_id: ID,
    price: u64,
    seller: address,
    timestamp: u64,
}

public struct HeroBought has copy, drop {
    list_hero_id: ID,
    price: u64,
    buyer: address,
    seller: address,
    timestamp: u64,
}

// YENİ EKLENEN EVENT:
public struct HeroDelisted has copy, drop {
    list_hero_id: ID,
    timestamp: u64,
}

// YENİ EKLENEN EVENT:
public struct HeroPriceChanged has copy, drop {
    list_hero_id: ID,
    new_price: u64,
    timestamp: u64,
}

// ========= FUNCTIONS =========

fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::public_transfer(admin_cap, ctx.sender());
}

public fun list_hero(nft: Hero, price: u64, ctx: &mut TxContext) {
    let id = object::new(ctx);
    let list_id = object::uid_to_inner(&id);
    
    let list_hero = ListHero {
        id,
        nft,
        price,
        seller: ctx.sender()
    };

    event::emit(HeroListed {
        list_hero_id: list_id,
        price,
        seller: ctx.sender(),
        timestamp: ctx.epoch_timestamp_ms()
    });

    transfer::share_object(list_hero);
}

#[allow(lint(self_transfer))]
public fun buy_hero(list_hero: ListHero, coin: Coin<SUI>, ctx: &mut TxContext) {
    let ListHero { id, nft, price, seller } = list_hero;

    assert!(coin.value() == price, EInvalidPayment);

    transfer::public_transfer(coin, seller);
    transfer::public_transfer(nft, ctx.sender());
    
    event::emit(HeroBought {
        list_hero_id: object::uid_to_inner(&id),
        price,
        buyer: ctx.sender(),
        seller: seller,
        timestamp: ctx.epoch_timestamp_ms()
    });

    object::delete(id);
}

// ========= ADMIN FUNCTIONS =========

// Event eklemek için ctx parametresi eklendi
public fun delist(_: &AdminCap, list_hero: ListHero, ctx: &mut TxContext) {
    let ListHero { id, nft, price: _, seller } = list_hero;

    // Event yayinliyoruz
    event::emit(HeroDelisted {
        list_hero_id: object::uid_to_inner(&id),
        timestamp: ctx.epoch_timestamp_ms()
    });

    transfer::public_transfer(nft, seller);
    object::delete(id);
}

// Event eklemek için ctx parametresi eklendi
public fun change_the_price(_: &AdminCap, list_hero: &mut ListHero, new_price: u64, ctx: &mut TxContext) {
    list_hero.price = new_price;

    // Event yayinliyoruz
    event::emit(HeroPriceChanged {
        list_hero_id: object::id(list_hero),
        new_price,
        timestamp: ctx.epoch_timestamp_ms()
    });
}

// ========= GETTER FUNCTIONS =========

#[test_only]
public fun listing_price(list_hero: &ListHero): u64 {
    list_hero.price
}

// ========= TEST ONLY FUNCTIONS =========

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx),
    };
    transfer::transfer(admin_cap, ctx.sender());
}