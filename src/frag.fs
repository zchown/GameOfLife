#version 330 core

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D prevState;
uniform vec2 texelSize;

float sampleAlive(vec2 uv) {
    // sample red channel; threshold to decide alive (0 or 1)
    return texture(prevState, uv).r > 0.5 ? 1.0 : 0.0;
}

void main() {
    vec2 uv = fragTexCoord;

    float count = 0.0;
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            if (x==0 && y==0) continue;
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            vec2 sampleUV = fract(uv + offset);
            count += sampleAlive(sampleUV);
        }
    }
    float selfAlive = sampleAlive(uv);
    float newAlive = 0.0;

    // Conway rules
    if (selfAlive > 0.5) {
        if (count == 2.0 || count == 3.0) newAlive = 1.0;
    } else {
        if (count == 3.0) newAlive = 1.0;
    }

    finalColor = vec4(newAlive, newAlive, newAlive, 1.0);
    //finalColor = vec4(1.0, 1.0, 0.0, 1.0);
    //finalColor = vec4(count / 8.0, selfAlive, 0.0, 1.0);
    //finalColor = vec4(1.0, 0.0, 0.0, 1.0);
}

