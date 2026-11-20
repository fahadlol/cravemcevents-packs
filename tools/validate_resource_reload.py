"""Regression checks for resource reload failures; no client rendering claims."""
import json
import re
from pathlib import Path

def validate_reload_resources(root: Path) -> None:
    errors = []
    for path in root.rglob('*.vsh'):
        source = path.read_text(encoding='utf-8')
        if 'gl_BaseVertexARB' in source:
            enabled = re.search(r'#extension\s+GL_ARB_shader_draw_parameters\s*:\s*(enable|require)', source)
            first_use = source.index('gl_BaseVertexARB')
            first_import = re.search(r'#(?:moj_import|include)', source)
            if not enabled or enabled.start() > first_use or (first_import and enabled.start() > first_import.start()):
                errors.append(f'{path}: draw parameters must be enabled before imports/use')
    for path in root.rglob('*.json'):
        data = json.loads(path.read_text(encoding='utf-8-sig'))
        if '/atlases/' in path.as_posix():
            for entry in data.get('sources', []):
                if entry.get('type', '').split(':')[-1] == 'directory':
                    for key in ('source', 'prefix'):
                        if ':' in entry.get(key, ''):
                            errors.append(f'{path}: atlas directory {key} is a path, not a resource identifier')
                elif entry.get('type', '').split(':')[-1] == 'single':
                    resource = entry.get('resource', '')
                    ns, sep, relative = resource.partition(':')
                    if sep and ns != 'minecraft' and not (root / 'assets' / ns / 'textures' / (relative + '.png')).is_file():
                        errors.append(f'{path}: missing atlas texture {resource}')
        if '/models/' in path.as_posix() and '/border/' in path.as_posix() and 'elements' in data:
            textures = data.get('textures', {})
            particle = textures.get('particle')
            seen = set()
            while isinstance(particle, str) and particle.startswith('#') and particle not in seen:
                seen.add(particle)
                particle = textures.get(particle[1:])
            if not particle or particle.startswith('#'):
                errors.append(f'{path}: unresolved border particle')
            else:
                ns, sep, relative = particle.partition(':')
                if not sep:
                    ns, relative = 'minecraft', ns
                if not (root / 'assets' / ns / 'textures' / (relative + '.png')).is_file():
                    errors.append(f'{path}: missing border particle texture {particle}')
    if errors:
        raise ValueError('\n'.join(errors))
    if (root / 'assets/cravemc/textures/font/hud/minimap.png').is_file():
        validate_hud_protocol(root)


def validate_hud_protocol(root: Path) -> None:
    font = json.loads((root / 'assets/cravemc/font/minimap_bossbar.json').read_text(encoding='utf-8'))
    providers = {ord(char): p for p in font['providers'] for row in p.get('chars', []) for char in row}
    assert providers[0xEA00]['file'] == 'cravemc:font/hud/minimap.png'
    assert providers[0xEA00]['height'] == 114
    for code in range(0xEB00, 0xEB00 + 18 * 101):
        p = providers[code]
        assert p['file'].startswith('cravemc:font/hud/'), code
        assert p['height'] == 14 and p['ascent'] == 9, code
    for code in [*range(0xE800, 0xE80B), *range(0xE810, 0xE813), *range(0xE820, 0xE823)]:
        assert providers[code]['file'].startswith('cravemc:font/hud/stats_'), code
    for p in providers.values():
        if p['file'].startswith('cravemc:font/hud/'):
            assert (root / 'assets/cravemc/textures' / p['file'].split(':', 1)[1]).is_file(), p['file']
    alpha_functions = set()
    for overlay, text_stem, border_stems in (
        ('overlay_1_21_11', 'rendertype_text', ['rendertype_item_entity_translucent_cull']),
        ('overlay_26', 'rendertype_text', ['entity', 'item']),
        ('overlay_26_2', 'text', ['entity', 'item']),
        ('overlay_26_3', 'text', ['entity', 'item']),
    ):
        core = root / overlay / 'assets/minecraft/shaders/core'
        vertex = (core / (text_stem + '.vsh')).read_text()
        assert 'crave_minimap_vertex' in vertex and 'gl_BaseVertexARB' not in vertex
        assert 'tag.r != 19 || tag.g != 37' in vertex and '!gui' in vertex
        assert 'ScreenSize.x - margin - 114.0 * scale' in vertex
        assert 'craveHudArrowShadow' not in vertex
        for stem in border_stems:
            fragment = (core / (stem + '.fsh')).read_text()
            assert 'crave_storm_color(craveStormTint.rgb)' in fragment
            function = re.search(r'float crave_storm_alpha\([^}]+\}', fragment).group()
            assert '(uv.x + uv.y)' not in function
            alpha_functions.add(function)
    assert len(alpha_functions) == 1, 'border versions must use the same alpha/animation function'

if __name__ == '__main__':
    import sys
    validate_reload_resources(Path(sys.argv[1]))
    print('PASS: extension declarations, atlas paths, border particle textures')
