/* disabled_protos.h
 * Declarations of routines for reading and writing protocols file that determine
 * enabling and disabling of protocols.
 *
 * Wireshark - Network traffic analyzer
 * By Gerald Combs <gerald@wireshark.org>
 * Copyright 1998 Gerald Combs
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef DISABLED_PROTOS_H
#define DISABLED_PROTOS_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/*
 * Write out a list of disabled protocols.
 *
 * On success, "*pref_path_return" is set to NULL.
 * On error, "*pref_path_return" is set to point to the pathname of
 * the file we tried to read - it should be freed by our caller -
 * and "*errno_return" is set to the error.
 */
WS_DLL_PUBLIC void
save_disabled_protos_list(char **pref_path_return, int *errno_return);

/*
 * Disable a particular protocol by name
 */

WS_DLL_PUBLIC void
proto_disable_proto_by_name(const char *name);

/*
 * Write out a list of enabled protocols (that default to being disabled)
 *
 * On success, "*pref_path_return" is set to NULL.
 * On error, "*pref_path_return" is set to point to the pathname of
 * the file we tried to read - it should be freed by our caller -
 * and "*errno_return" is set to the error.
 */
WS_DLL_PUBLIC void
save_enabled_protos_list(char **pref_path_return, int *errno_return);


/*
 * Enable a particular protocol by name.  This will only enable
 * protocols that are disabled by default.  All others will be ignored.
 */
WS_DLL_PUBLIC void
proto_enable_proto_by_name(const char *name);

/*
 * Write out a list of disabled heuristic dissectors.
 *
 * On success, "*pref_path_return" is set to NULL.
 * On error, "*pref_path_return" is set to point to the pathname of
 * the file we tried to read - it should be freed by our caller -
 * and "*errno_return" is set to the error.
 */
WS_DLL_PUBLIC void
save_disabled_heur_dissector_list(char **pref_path_return, int *errno_return);

/*
 * Enable/disable a particular heuristic dissector by name
 * On success (found the protocol), return TRUE.
 * On failure (didn't find the protocol), return FALSE.
 */
WS_DLL_PUBLIC gboolean
proto_enable_heuristic_by_name(const char *name, gboolean enable);

/*
 * Read the files that enable and disable protocols and heuristic
 * dissectors.  Report errors through the UI.
 */
WS_DLL_PUBLIC void
read_enabled_and_disabled_protos(void);

/*
 * Free the internal structures
 */
extern void
enabled_and_disabled_protos_cleanup(void);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* DISABLED_PROTOS_H */
