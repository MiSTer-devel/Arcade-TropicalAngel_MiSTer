def generate_rgb333_to_rgb888_lookup_table():
    lookup_table = {}
    
    for i in range(512):  # 2^9 = 512 combinations
        # Extract RGB 333 components
        r_3bit = (i >> 6) & 0x07  # bits 6-8
        g_3bit = (i >> 3) & 0x07  # bits 3-5
        b_3bit = i & 0x07         # bits 0-2

        # Scale to RGB 888
        r_8bit = int(r_3bit * 255 / 7)
        g_8bit = int(g_3bit * 255 / 7)
        b_8bit = int(b_3bit * 255 / 7)

        # Convert to binary string representation
        key_bin = format(i, '09b')
        value_bin = format(r_8bit, '08b') + format(g_8bit, '08b') + format(b_8bit, '08b')

        # Store in lookup table
        lookup_table[key_bin] = value_bin

    return lookup_table

# Generate the lookup table
rgb333_to_rgb888 = generate_rgb333_to_rgb888_lookup_table()

# Optional: print the lookup table
for key, value in rgb333_to_rgb888.items():
    print(f"{key} : {value};")
