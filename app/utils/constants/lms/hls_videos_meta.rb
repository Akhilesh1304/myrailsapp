
module Constants
  module HlsVideosMeta
    STATUS_INITIALIZED = 'Initialized'
    STATUS_TRANSCODING = 'Transcoding'
    STATUS_TRANSCODED = 'Transcoded'
    STATUS_TRANSCODING_FAILED = 'Transcoding Failure'
    STATUS_POST_PROCESSING = 'Post Processing'
    STATUS_POST_PROCESSING_FAILED = 'Post Processing Failure'
    STATUS_COMPLETE = 'Complete'
    CAPTION_LANGUAGE_EN = 'en'
    FORMAT_HLS_V3 = 'HLSv3'
    HLS_VIDEOS_DISTRIBUTION = Settings.hls_medias_cloudfront_url
    LANGUAGE_MAP = {
      'en' => 'ENG', 'es' => 'SPA', 'fr' => 'FRA', 'de' => 'DEU', 'zh' => 'ZHO', 'ar' => 'ARA', 'hi' => 'HIN',
      'ja' => 'JPN', 'ru' => 'RUS', 'pt' => 'POR', 'it' => 'ITA', 'ur' => 'URD', 'vi' => 'VIE', 'ko' => 'KOR',
      'pa' => 'PAN', 'ab' => 'ABK', 'aa' => 'AAR', 'af' => 'AFR', 'ak' => 'AKA', 'sq' => 'SQI', 'am' => 'AMH',
      'hy' => 'HYE', 'as' => 'ASM', 'av' => 'AVA', 'ae' => 'AVE', 'ay' => 'AYM', 'az' => 'AZE', 'bm' => 'BAM',
      'ba' => 'BAK', 'eu' => 'EUS', 'be' => 'BEL', 'bn' => 'BEN', 'bh' => 'BIH', 'bi' => 'BIS', 'bs' => 'BOS',
      'br' => 'BRE', 'bg' => 'BUL', 'my' => 'MYA', 'ca' => 'CAT', 'km' => 'KHM', 'ch' => 'CHA', 'ce' => 'CHE',
      'ny' => 'NYA', 'cu' => 'CHU', 'cv' => 'CHV', 'kw' => 'COR', 'co' => 'COS', 'cr' => 'CRE', 'hr' => 'HRV',
      'cs' => 'CES', 'da' => 'DAN', 'dv' => 'DIV', 'nl' => 'NLD', 'dz' => 'DZO', 'eo' => 'EPO',
      'et' => 'EST', 'ee' => 'EWE', 'fo' => 'FAO', 'fj' => 'FIJ', 'fi' => 'FIN', 'ff' => 'FUL',
      'gd' => 'GLA', 'gl' => 'GLG', 'lg' => 'LUG', 'ka' => 'KAT', 'el' => 'ELL', 'gn' => 'GRN', 'gu' => 'GUJ',
      'ht' => 'HAT', 'ha' => 'HAU', 'he' => 'HEB', 'hz' => 'HER', 'ho' => 'HMO', 'hu' => 'HUN', 'is' => 'ISL',
      'io' => 'IDO', 'ig' => 'IBO', 'id' => 'IND', 'ia' => 'INA', 'ie' => 'ILE', 'iu' => 'IKU', 'ik' => 'IPK',
      'ga' => 'GLE', 'jv' => 'JAV', 'kl' => 'KAL', 'kn' => 'KAN', 'kr' => 'KAU', 'ks' => 'KAS', 'kk' => 'KAZ',
      'ki' => 'KIK', 'rw' => 'KIN', 'ky' => 'KIR', 'kv' => 'KOM', 'kg' => 'KON', 'kj' => 'KUA', 'ku' => 'KUR',
      'lo' => 'LAO', 'la' => 'LAT', 'lv' => 'LAV', 'li' => 'LIM', 'ln' => 'LIN', 'lt' => 'LIT', 'lu' => 'LUB',
      'lb' => 'LTZ', 'mk' => 'MKD', 'mg' => 'MLG', 'ms' => 'MSA', 'ml' => 'MAL', 'mt' => 'MLT', 'gv' => 'GLV',
      'mi' => 'MRI', 'mr' => 'MAR', 'mh' => 'MAH', 'mn' => 'MON', 'na' => 'NAU', 'nv' => 'NAV', 'nd' => 'NDE',
      'nr' => 'NBL', 'ng' => 'NDO', 'ne' => 'NEP', 'se' => 'SME', 'no' => 'NOR', 'nb' => 'NOB', 'nn' => 'NNO',
      'oc' => 'OCI', 'oj' => 'OJI', 'or' => 'ORI', 'om' => 'ORM', 'os' => 'OSS', 'pi' => 'PLI', 'fa' => 'FAS',
      'pl' => 'POL', 'ps' => 'PUS', 'qu' => 'QUE', 'ro' => 'RON', 'rm' => 'ROH', 'rn' => 'RUN', 'sm' => 'SMO',
      'sg' => 'SAG', 'sa' => 'SAN', 'sc' => 'SRD', 'sr' => 'SRB', 'sn' => 'SNA', 'ii' => 'III', 'sd' => 'SND',
      'si' => 'SIN', 'sk' => 'SLK', 'sl' => 'SLV', 'so' => 'SOM', 'st' => 'SOT', 'su' => 'SUN', 'sw' => 'SWA',
      'ss' => 'SSW', 'sv' => 'SWE', 'tl' => 'TGL', 'ty' => 'TAH', 'tg' => 'TGK', 'ta' => 'TAM', 'tt' => 'TAT',
      'te' => 'TEL', 'th' => 'THA', 'bo' => 'BOD', 'ti' => 'TIR', 'to' => 'TON', 'ts' => 'TSO', 'tn' => 'TSN',
      'tr' => 'TUR', 'tk' => 'TUK', 'tw' => 'TWI', 'ug' => 'UIG', 'uk' => 'UKR', 'uz' => 'UZB', 've' => 'VEN',
      'vo' => 'VOL', 'wa' => 'WLN', 'cy' => 'CYM', 'fy' => 'FRY', 'wo' => 'WOL', 'xh' => 'XHO', 'yi' => 'YID',
      'yo' => 'YOR', 'za' => 'ZHA', 'zu' => 'ZUL'
    }.freeze
  end
end


