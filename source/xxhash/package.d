/*
 * This file is part of xxhash-d.
 *
 * Copyright © 2021 Serpent OS Developers
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module xxhash;

import xxhash.binding;
import std.exception : enforce;

/**
 * Templated XXH3 hash support
 */
public final class XXH3(uint B)
{

    /**
     * Construct a new XXHash3 instance
     */
    this()
    {
        state = XXH3_createState();
        reset();
    }

    ~this()
    {
        XXH3_freeState(state);
        state = null;
    }

    /**
     * Reset the internal state. This is done upon constrution.
     */
    void reset()
    {
        static if (BitWidth == 64)
        {
            XXH3_64bits_reset(state);
        }
        else static if (BitWidth == 128)
        {
            XXH3_128bits_reset(state);
        }
    }

    /**
     * Put some data to the digest
     */
    void put(scope const(ubyte)[] data...) @trusted
    {
        XXH_errorcode code;
        static if (BitWidth == 64)
        {
            code = XXH3_64bits_update(state, data.ptr, data.length);
        }
        else static if (BitWidth == 128)
        {
            code = XXH3_128bits_update(state, data.ptr, data.length);
        }

        enforce(code == XXH_errorcode.ok, "XXH3.put(): Failed to put data");
    }

    /**
     * Return non-allocated finished hash digest
     */
    ubyte[BitWidth / 8] finish() @trusted
    {
        ubyte[BitWidth / 8] ret;
        HashType xxh3_ret;
        CanonType xxh3_canon;

        static if (BitWidth == 64)
        {
            xxh3_ret = XXH3_64bits_digest(state);
            XXH64_canonicalFromHash(&xxh3_canon, xxh3_ret);

        }
        else static if (BitWidth == 128)
        {
            xxh3_ret = XXH3_128bits_digest(state);
            XXH128_canonicalFromHash(&xxh3_canon, xxh3_ret);
        }

        ret = xxh3_canon.digest;
        reset();
        return ret;
    }

private:

    /* Store the bit width */
    alias BitWidth = B;

    /* Must be 64-bit or 128-bit only */
    static assert(BitWidth == 64 || BitWidth == 128, "Unsupported BitWidth");

    XXH3_state_t* state = null;

    /* Define hash + canon types */
    static if (BitWidth == 64)
    {
        alias HashType = XXH64_hash_t;
        alias CanonType = XXH64_canonical_t;
    }
    else static if (BitWidth == 128)
    {
        alias HashType = XXH128_hash_t;
        alias CanonType = XXH128_canonical_t;
    }
}

/**
 * 64-bit xxhash3
 */
alias XXH3_64 = XXH3!64;

/**
 * 128-bit xxhash3
 */
alias XXH3_128 = XXH3!128;

@("A do nothing unit test")
private unittest
{
    import std.stdio : File;
    import std.mmfile : MmFile;

    /* Ensure read of whole file */
    auto ff = new MmFile(File("README.md", "rb"));
    auto fc = cast(ubyte[]) ff[0 .. $];

    auto t = new XXH3_64;
    t.put(fc);

    import std.stdio : writeln;
    import std.digest : toHexString, LetterCase;

    auto dg = t.finish();
    writeln(toHexString!(LetterCase.lower)(dg));

    auto t2 = new XXH3_128;
    t2.put(fc);
    auto dg2 = t2.finish();
    writeln(toHexString!(LetterCase.lower)(dg2));
}
