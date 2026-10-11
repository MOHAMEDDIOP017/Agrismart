#!/usr/bin/env python3
"""Reconstruit les fontes Nunito embarquees dans assets/fonts/.

    python tool/fontes_nunito.py

Le script telecharge la fonte variable officielle, en extrait les quatre
graisses utilisees par le theme, puis reduit chacune aux caracteres dont
l'application a besoin. Il est reproductible : relance-le apres toute mise a
jour de Nunito ou tout ajout de caractere a l'interface.

Pourquoi des instances statiques plutot que le fichier variable
---------------------------------------------------------------
Sur une fonte variable, l'axe de graisse n'est pilote que par
`fontVariations`. Un `TextStyle(fontWeight: FontWeight.bold)` reste au trace
par defaut de l'axe, et un `copyWith(fontWeight:)` ne produit rien. La mesure
l'a confirme : deux graisses opposees rendaient exactement la meme largeur.
Comme le code compte 258 usages de `fontWeight`, ce silence aurait cree un
piege durable. Quatre fichiers statiques, declares une par graisse dans
`pubspec.yaml`, retablissent le comportement que tout le code Flutter attend.

Pourquoi reduire les caracteres
-------------------------------
Nunito couvre le latin etendu, le cyrillique et le vietnamien. L'application
affiche du francais, du wolof et des nombres. La reduction fait passer les
quatre instances de 517 Ko a 203 Ko, soit moins que le fichier variable
d'origine, sans perdre un caractere utile.

Prerequis : pip install fonttools
Licence de la fonte : SIL Open Font License 1.1, voir assets/fonts/OFL.txt.
"""
import os
import sys
import urllib.request

from fontTools import subset
from fontTools import ttLib
from fontTools.varLib import instancer

SOURCE_VARIABLE = (
    'https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/'
    'Nunito%5Bwght%5D.ttf'
)
SOURCE_LICENCE = (
    'https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/OFL.txt'
)

DESTINATION = os.path.join('assets', 'fonts')

# Graisses declarees dans pubspec.yaml, et seules utilisees par le theme.
GRAISSES = [
    (400, 'Regular'),    # corps de texte
    (600, 'SemiBold'),   # libelles, titres de carte
    (700, 'Bold'),       # titres, boutons
    (800, 'ExtraBold'),  # chiffres mis en avant
]

# Plages de caracteres conservees.
PLAGES = [
    (0x0020, 0x007E),  # latin de base, chiffres, ponctuation ASCII
    (0x00A0, 0x00FF),  # accents francais, guillemets, degre, n-tilde
    (0x0100, 0x017F),  # latin etendu A : eng du wolof, oe, s-caron
    (0x0192, 0x0192),  # f crochet
    (0x0254, 0x0254),  # o ouvert (API)
    (0x025B, 0x025B),  # e ouvert (API)
    (0x02B0, 0x02FF),  # lettres modificatives
    (0x2000, 0x206F),  # apostrophe courbe, tirets, points de suspension
    (0x20A0, 0x20BF),  # symboles monetaires
    (0x2122, 0x2122),  # marque deposee
    (0x2190, 0x2193),  # fleches simples
    (0x2212, 0x2212),  # signe moins
    (0x25A0, 0x25FF),  # formes geometriques (puces)
    (0xFB00, 0xFB06),  # ligatures fi, fl
]

# Caracteres dont la presence est verifiee apres reduction. Le meme controle
# existe cote Dart dans test/theme_graisse_test.dart, qui le rejoue a chaque
# execution de la suite.
A_VERIFIER = (
    'AaBbCcDdEeFfGgIiJjKkLlMmNnOoPpQqRrSsTtUuWwXxYyZz'
    '0123456789'
    'àâäéèêëîïôöùûüÿçœÀÂÉÈÊËÎÏÔÖÙÛÜÇŒ'   # francais
    'ñÑŋŊóÓ'                              # wolof
    '«»’…·–—'    # ponctuation francaise
    '°%:;,.!?()[]/+-= €'
)


def telecharger(url, chemin):
    print('  telechargement de %s' % os.path.basename(chemin))
    with urllib.request.urlopen(url, timeout=60) as reponse:
        donnees = reponse.read()
    with open(chemin, 'wb') as sortie:
        sortie.write(donnees)
    return len(donnees)


def main():
    os.makedirs(DESTINATION, exist_ok=True)
    variable = os.path.join(DESTINATION, '.Nunito-Variable.ttf')

    print('1. Source officielle')
    taille_variable = telecharger(SOURCE_VARIABLE, variable)
    telecharger(SOURCE_LICENCE, os.path.join(DESTINATION, 'OFL.txt'))

    with ttLib.TTFont(variable) as controle:
        if 'fvar' not in controle:
            sys.exit('La source telechargee n est pas une fonte variable.')
        axes = {a.axisTag: (a.minValue, a.maxValue)
                for a in controle['fvar'].axes}
    print('  axes disponibles : %s' % axes)
    mini, maxi = axes['wght']
    for poids, _ in GRAISSES:
        if not mini <= poids <= maxi:
            sys.exit('La graisse %d sort de l axe wght (%g a %g).'
                     % (poids, mini, maxi))

    caracteres = []
    for debut, fin in PLAGES:
        caracteres.extend(range(debut, fin + 1))

    print('')
    print('2. Instanciation et reduction')
    total = 0
    for poids, nom in GRAISSES:
        chemin = os.path.join(DESTINATION, 'Nunito-%s.ttf' % nom)

        police = ttLib.TTFont(variable)
        instancer.instantiateVariableFont(
            police, {'wght': poids}, updateFontNames=True, inplace=True)
        police.save(chemin)
        police.close()
        apres_instance = os.path.getsize(chemin)

        options = subset.Options()
        options.layout_features = ['*']
        options.name_IDs = ['*']
        options.name_legacy = True
        options.notdef_outline = True
        options.recalc_bounds = True
        reduite = subset.load_font(chemin, options)
        reducteur = subset.Subsetter(options=options)
        reducteur.populate(unicodes=caracteres)
        reducteur.subset(reduite)
        subset.save_font(reduite, chemin, options)
        reduite.close()
        apres_reduction = os.path.getsize(chemin)
        total += apres_reduction

        with ttLib.TTFont(chemin) as verif:
            couverts = set()
            for sous in verif['cmap'].tables:
                couverts.update(sous.cmap.keys())
        manquants = sorted({c for c in A_VERIFIER if ord(c) not in couverts})
        if manquants:
            sys.exit('Caracteres absents de Nunito-%s : %s'
                     % (nom, ''.join(manquants)))

        print('  Nunito-%-10s wght %-4d  %6d -> %6d octets  couverture ok'
              % (nom, poids, apres_instance, apres_reduction))

    os.remove(variable)

    print('')
    print('3. Resultat')
    print('  fonte variable d origine : %6d octets' % taille_variable)
    print('  quatre instances reduites: %6d octets' % total)
    print('')
    print('  Les fichiers sont declares dans pubspec.yaml, section fonts.')


if __name__ == '__main__':
    main()
