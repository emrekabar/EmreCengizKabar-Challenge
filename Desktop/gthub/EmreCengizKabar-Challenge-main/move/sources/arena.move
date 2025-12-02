module challenge::arena;

use challenge::hero::Hero;
use sui::event;

// ========= STRUCTS =========

public struct Arena has key, store {
    id: UID,
    warrior: Hero,
    owner: address,
}

// ========= EVENTS =========

public struct ArenaCreated has copy, drop {
    arena_id: ID,
    timestamp: u64,
}

public struct ArenaCompleted has copy, drop {
    winner_hero_id: ID,
    loser_hero_id: ID,
    timestamp: u64,
}

// ========= FUNCTIONS =========
public fun create_arena(hero: Hero, ctx: &mut TxContext) {
        let id = object::new(ctx);
        let arena_id = object::uid_to_inner(&id);

        let arena = Arena {
            id,
            warrior: hero,
            owner: ctx.sender()
        };


        event::emit(ArenaCreated {
            arena_id,
            timestamp: ctx.epoch_timestamp_ms()
        });

        transfer::share_object(arena);
    }

#[allow(lint(self_transfer))]
public fun battle(hero: Hero, arena: Arena, ctx: &mut TxContext) {
        let Arena { id, warrior, owner } = arena;
        
        let warrior_id = object::id(&warrior);
        let hero_id = object::id(&hero);
        
        if (hero.hero_power() > warrior.hero_power()) {
            transfer::public_transfer(hero, ctx.sender());
            transfer::public_transfer(warrior, ctx.sender());
            
            
            event::emit(ArenaCompleted {
                winner_hero_id: hero_id,
                loser_hero_id: warrior_id,
                timestamp: ctx.epoch_timestamp_ms()
            });
        } else {
            transfer::public_transfer(hero, owner);
            transfer::public_transfer(warrior, owner);
            
            
            event::emit(ArenaCompleted {
                winner_hero_id: warrior_id,
                loser_hero_id: hero_id,
                timestamp: ctx.epoch_timestamp_ms()
            });
        };
        
        object::delete(id);
    }

