/*
 *
 * reapi_molotov
 *
 * api
 *
*/

#if defined _reapi_molotov_api_included
 #endinput
#endif

#define _reapi_molotov_api_included

/*
 *
 * Gives the player a Molotov cocktail immediately (provided that he is alive)
 *
 * Parameter: Player ID
 *
 * @returns nothing
 *
*/
native rp_getting_molotov(const player_id);

/*
 *
 * Check if the player has a Molotov cocktail
 *
 * Parameter: Player ID
 *
 * @returns 1 if present, 0 if not.
 *
*/
native rp_molotov_check(const player_id);

/*
 *
 * Intercept an event when the player is in the epicenter of the explosion and takes damage.
 *
 * Parameter: ID attacker, ID victim, damage
 *
 * @sends information about the attacker, victim and damage
 *
*/
forward rp_player_takes_damage(const attacker, const victim, const Float:damage);

/*
 *
 * Interception of the event, at the moment when the molotov explodes.
 *
 * Parameter: ID attacker
 *
 * @sends information about the attacker who threw the molotov
 *
*/
forward rp_molotov_exploded(const attacker);

/*
 *
 * Interception of an event when a molotov dropped from a player after death.
 *
 * Parameter: Player ID, Entity ID
 *
 * @sends information about the player who was killed (or died) and he had a molotov and he fell out
 *
*/
forward rp_molotov_dropped(const player_id, const entity);

/*
 *
 * Interception of the event, at the moment when the player threw a molotov.
 *
 * Parameter: Player ID, Entity ID
 *
 * @sends information about the player who threw the molotov
 *
*/
forward rp_player_threw_molotov(const player_id, const entity);

/*
 *
 * Intercept the event when the player received a molotov.
 *
 * Parameter: Player ID, Item ID
 *
 * @sends information about the player when he received molotov.
 *
*/
forward rp_player_received_molotov(const player_id, const item);

/*
 *
 * Interception of the event when the player raises the molotov
 *
 * Parameter: Player ID, Item ID
 *
 * @sends information about the player when he picks up the molotov
 *
*/
forward rp_raising_molotov(const player_id, const item);