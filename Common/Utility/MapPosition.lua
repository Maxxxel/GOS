--[[
  Map Position 1.2 by Husky and Manciuszz (edited by Maxxxel for Season 5)
	========================================================================

	Enables you to easily query the semantic position of a unit in the map.
	The jungle (as well as the river) is separated into inner and outer jungle
	to distinct roaming from warding champions.

	The following methods exist and return true if the unit is inside the
	specified area (or false otherwise):

	-- River Positions --------------------------------------------------------

	MapPosition:inRiver(unit)
	MapPosition:inTopRiver(unit)
	MapPosition:inTopInnerRiver(unit)
	MapPosition:inTopOuterRiver(unit)
	MapPosition:inBottomRiver(unit)
	MapPosition:inBottomInnerRiver(unit)
	MapPosition:inBottomOuterRiver(unit)
	MapPosition:inOuterRiver(unit)
	MapPosition:inInnerRiver(unit)

	-- Base Positions ---------------------------------------------------------

	MapPosition:inBase(unit)
	MapPosition:inLeftBase(unit)
	MapPosition:inRightBase(unit)

	-- Lane Positions ---------------------------------------------------------

	MapPosition:onLane(unit)
	MapPosition:onTopLane(unit)
	MapPosition:onMidLane(unit)
	MapPosition:onBotLane(unit)

	-- Jungle Positions -------------------------------------------------------

	MapPosition:inJungle(unit)
	MapPosition:inOuterJungle(unit)
	MapPosition:inInnerJungle(unit)
	MapPosition:inLeftJungle(unit)
	MapPosition:inLeftOuterJungle(unit)
	MapPosition:inLeftInnerJungle(unit)
	MapPosition:inTopLeftJungle(unit)
	MapPosition:inTopLeftOuterJungle(unit)
	MapPosition:inTopLeftInnerJungle(unit)
	MapPosition:inBottomLeftJungle(unit)
	MapPosition:inBottomLeftOuterJungle(unit)
	MapPosition:inBottomLeftInnerJungle(unit)
	MapPosition:inRightJungle(unit)
	MapPosition:inRightOuterJungle(unit)
	MapPosition:inRightInnerJungle(unit)
	MapPosition:inTopRightJungle(unit)
	MapPosition:inTopRightOuterJungle(unit)
	MapPosition:inTopRightInnerJungle(unit)
	MapPosition:inBottomRightJungle(unit)
	MapPosition:inBottomRightOuterJungle(unit)
	MapPosition:inBottomRightInnerJungle(unit)
	MapPosition:inTopJungle(unit)
	MapPosition:inTopOuterJungle(unit)
	MapPosition:inTopInnerJungle(unit)
	MapPosition:inBottomJungle(unit)
	MapPosition:inBottomOuterJungle(unit)
	MapPosition:inBottomInnerJungle(unit)


	The following methods return true if the point is inside a wall or
	intersects a wall:

	-- Wall Functions ---------------------------------------------------------

	MapPosition:inWall(point)
	MapPosition:intersectsWall(pointOrLinesegment)

	Changelog
	~~~~~~~~~

	1.0	- initial release with the most important map areas (jungle, river,
		  lanes and so on)
	1.1	- added walls and the corresponding query methods
		- added a spatial hashmap for faster realtime queries
		- added caching for instant loading
	1.2 -updated regions and walls for S5 (Maxxxel)
	
--]]

-- Dependencies ----------------------------------------------------------------

require "2DGeometry"

-- Config ----------------------------------------------------------------------

regions = {
	topLeftOuterJungle     = Polygon(Point(2272, 11423),	Point(2172,5328), 		Point(3726,4896),  	 Point(5998,7228)), --updated
	topLeftInnerJungle     = Polygon(Point(2654,5841),  	Point(3919,5669),			Point(5724,7537),  	 Point(2826,10274)), --updated
	topOuterRiver          = Polygon(Point(2332,11727),  	Point(2971,12355),	 	Point(7370,8024),  Point(6678,7488)), --updated
	topInnerRiver          = Polygon(Point(6010,8242),  	Point(6586,8786), 	Point(3794,10992),  Point(3224,10706)), --updated
	topRightOuterJungle    = Polygon(Point(4080,12690),  	Point(9564,12912), 	Point(10004,11046),  Point(7618,8592)), --updated
	topRightInnerJungle    = Polygon(Point(7140,8944),  Point(4347,12061), Point(8552,12319),  Point(9328,11142)), --updated
	bottomLeftOuterJungle  = Polygon(Point(5237,2053),  Point(10950,2058),  Point(7248,6286),  Point(4867,3772)), --updated
	bottomLeftInnerJungle  = Polygon(Point(5950,2504),  Point(5824,3827),  Point(8033,5214),   Point(10432,2800)), --updated
	bottomOuterRiver       = Polygon(Point(11774,2775), Point(12411,3573),  Point(8404,7259),   Point(7453,6504)), --updated
	bottomInnerRiver       = Polygon(Point(8214,6043), Point(9000,6623),  Point(12164,5195),   Point(10976,3383)), --updated
	bottomRightOuterJungle = Polygon(Point(12618,9626), Point(10955,10063),  Point(8719,7425), Point(12477,3914)), --updated
	bottomRightInnerJungle = Polygon(Point(12257,4968), Point(11998,8657),  Point(10533,8888),  Point(9671,7232)), --updated
	leftMidLane            = Polygon(Point(6773,6186),   Point(5880,6833),  Point(3731,4522),   Point(4469,3883)), --updated
	centerMidLane          = Polygon(Point(7971,8752),  Point(8925,8060),  Point(6773,6186),   Point(5880,6833)), --updated
	rightMidLane           = Polygon(Point(10314,10856),  Point(10941,10318),  Point(8925,8060),  Point(7971,8752)), --updated
	leftBotLane            = Polygon(Point(5044,555),   Point(5060,1786),  Point(11320,1926),  Point(11713,392)), --updated
	centerBotLane          = Polygon(Point(11320,1926),  Point(11713,392), Point(14672,2768),  Point(12638,3411)), --updated
	rightBotLane           = Polygon(Point(14672,2768),  Point(12638,3411), Point(13066,9845),  Point(14486,9966)), --updated
	leftTopLane            = Polygon(Point(726,5116),    Point(1685,5020),    Point(2004,11562),  Point(69,11327)), --updated
	centerTopLane          = Polygon(Point(2004,11562),  Point(69,11327),    Point(2005,14731),  Point(3169,12753)), --updated
	rightTopLane           = Polygon(Point(2005,14731),  Point(3169,12753), Point(9643,13152),  Point(9702,14519)), --updated
	inLeftBase						 = Polygon(Point(162,144),			Point(480,4984),	Point(4197,4239),		Point(4887,633)), --selfmade
	inRightBase						 = Polygon(Point(14603,14657)	,Point(9788,14660),	Point(10625,10653),	Point(14586,9974)), --selfmade
}

walls = {
	Polygon(Point(831,11392),Point(657,9872),Point(664,8448),Point(717,4931),Point(471,4548),Point(475,3930),Point(532,3655),Point(458,3367),Point(467,2835),Point(531,2549),Point(457,2254),Point(465,1547),Point(364,868),Point(71,596),Point(116,562),Point(106,14735)),
	Polygon(Point(748,11438),Point(965,12183),Point(1271,12797),Point(1768,13393),Point(2774,13864),Point(3685,14175),Point(5901,14167),Point(106,14735)),
	Polygon(Point(5893,14167),Point(7603,14183),Point(8944,14273),Point(9978,14211),Point(10477,14407),Point(13247,14376),Point(13489,14261),Point(13860,14419),Point(13904,14681),Point(14505,14607),Point(14652,14741),Point(8695,14735),Point(106,14735)),
	Polygon(Point(14439,14687),Point(14610,14455),Point(14639,14080),Point(14489,14004),Point(14367,13577),Point(14368,13312),Point(14354,10486),Point(14146,10068),Point(14111,9595),Point(14206,8552),Point(14164,3974),Point(13927,3236),Point(13366,2192),Point(12827,1535),Point(12179,1121),Point(11605,917),Point(10678,758),Point(9697,706),Point(4844,665),Point(4545,497),Point(4069,394),Point(1395,387),Point(889,103),Point(349,124),Point(208,249),Point(116,562),Point(6371,96),Point(14507,210),Point(14588,9045),Point(14652,14741)),
	Polygon(Point(1297,1404),Point(1802,1399),Point(1799,1919),Point(1288,1937)),
	Polygon(Point(1462,375),Point(1324,434),Point(1156,371),Point(988,126),Point(662,108),Point(305,70),Point(51,284),Point(116,657),Point(104,918),Point(74,138),Point(49,182),Point(280,182),Point(1466,71),Point(9147,92),Point(9106,673)),
	Polygon(Point(2070,1705),Point(2274,1718),Point(2266,1915),Point(2074,1900)),	
	Polygon(Point(9089,693),Point(10701,742),Point(11635,925),Point(12167,1129),Point(12810,1530),Point(13357,2196),Point(13783,2860),Point(14644,2308)),	
	Polygon(Point(1637,2160),Point(1834,2174),Point(1841,2355),Point(1665,2375)),
	Polygon(Point(3299,1112),Point(3613,1104),Point(3620,1391),Point(3352,1421)),
	Polygon(Point(4167,1177),Point(4368,1168),Point(4368,1354),Point(4182,1371)),
	Polygon(Point(3879,2287),Point(4166,2309),Point(4130,2515),Point(3855,2407)),
	Polygon(Point(3170,3031),Point(3424,3236),Point(3196,3414),Point(3005,3254)),
	Polygon(Point(3560,3587),Point(3783,3705),Point(3622,3828),Point(3503,3698)),
	Polygon(Point(2322,3948),Point(2596,3915),Point(2577,4148),Point(2345,4175)),
	Polygon(Point(1055,3416),Point(1290,3423),Point(1319,3743),Point(1004,3751)),	
	Polygon(Point(1066,4174),Point(1276,4193),Point(1264,4379),Point(1062,4349)),
	Polygon(Point(1664,4772),Point(1877,4713),Point(2007,4798),Point(2438,4755),Point(2530,4774),Point(2842,4627),Point(3058,4629),Point(3600,4328),Point(3755,4502),Point(3084,4832),Point(2439,4998),Point(1944,4997),Point(1834,5050),Point(1790,5015),Point(1665,5005),Point(1657,4776)),
	Polygon(Point(4301,3688),Point(4483,3805),Point(4619,3651),Point(4641,3496),Point(4848,3115),Point(4961,2544),Point(4976,2040),Point(5044,1901),Point(4973,1757),Point(4793,1702),Point(4707,1922),Point(4814,2074),Point(4771,2491),Point(4649,3014),Point(4366,3513),Point(4294,3677)),	
	Polygon(Point(1417,6588),Point(1609,6594),Point(1615,6779),Point(1414,6761)),
	Polygon(Point(879,10342),Point(1069,10335),Point(1083,10517),Point(892,10516)),	
	Polygon(Point(4201,13996),Point(4217,13768),Point(4419,13769),Point(4424,13988)),
	Polygon(Point(7835,13294),Point(8048,13293),Point(8045,13532),Point(7834,13533)),
	Polygon(Point(10369,13550),Point(10585,13548),Point(10584,13762),Point(10392,13767)),
	Polygon(Point(11110,13522),Point(11408,13534),Point(11413,13832),Point(11120,13840)),
	Polygon(Point(12529,12965),Point(12765,13012),Point(12688,13230),Point(12458,13176)),
	Polygon(Point(12979,12491),Point(13186,12574),Point(13147,12751),Point(12909,12699)),
	Polygon(Point(12998,13008),Point(13474,13018),Point(13489,13476),Point(13001,13479)),
	Polygon(Point(13602,11097),Point(13810,11318),Point(13602,11555),Point(13396,11318)),
	Polygon(Point(13626,10432),Point(13760,10591),Point(13627,10721),Point(13476,10584)),
	Polygon(Point(12352,10803),Point(12526,10935),Point(12462,11082),Point(12276,10986)),
	Polygon(Point(13323,8083),Point(13470,8232),Point(13337,8365),Point(13185,8225)),
	Polygon(Point(13864,4366),Point(14012,4513),Point(13863,4653),Point(13726,4500)),
	Polygon(Point(10480,912),Point(10638,1031),Point(10495,1149),Point(10364,1025)),
	Polygon(Point(6907,1360),Point(7054,1485),Point(6907,1603),Point(6777,1474)),
	Polygon(Point(5064,4673),Point(5172,4861),Point(5019,4943),Point(4901,4803)),	
	Polygon(Point(5851,6259),Point(5971,6399),Point(5841,6522),Point(5704,6397)),
	Polygon(Point(8844,8401),Point(9076,8419),Point(9069,8623),Point(8845,8603)),
	Polygon(Point(9667,10008),Point(9877,10017),Point(9882,10231),Point(9652,10211)),
	Polygon(Point(10826,12436),Point(11034,12514),Point(10818,12671),Point(10748,12490)),
	Polygon(Point(11436,11510),Point(11755,11556),Point(11751,11842),Point(11447,11809)),
	Polygon(Point(11039,11096),Point(11252,11129),Point(11258,11313),Point(11043,11319)),		
	Polygon(Point(5446,1781),Point(5932,1783),Point(5853,2085),Point(5871,2516),Point(5999,2706),Point(6246,2798),Point(5829,3460),Point(5597,3421),Point(5456,3222),Point(5493,2898),Point(5447,1792),Point(5663,1743)),
	Polygon(Point(5409,3769),Point(5610,3783),Point(5751,4290),Point(6077,4788),Point(5577,4917),Point(4823,4316),Point(5075,4004),Point(5267,3770)),
	Polygon(Point(6469,4857),Point(6707,4825),Point(6783,5311),Point(6752,5597),Point(7082,5627),Point(7227,5313),Point(7468,5250),Point(7696,5301),Point(7662,5574),Point(7489,5745),Point(6933,6042),Point(6744,6180),Point(5907,5377),Point(5898,5261),Point(6145,5300),Point(6382,5347),Point(6470,4827)),
	Polygon(Point(6630,4530),Point(6418,4448),Point(6261,4213),Point(6169,3802),Point(6434,3421),Point(6820,3140),Point(6980,3110),Point(7111,3219),Point(7139,3464),Point(6979,3663),Point(6588,3810),Point(6556,4157)),
	Polygon(Point(6432,1716),Point(7863,1758),Point(7924,1914),Point(7841,2052),Point(7558,2113),Point(7384,2346),Point(7151,2510),Point(6835,2494),Point(6472,2387),Point(6314,2278),Point(6281,2138),Point(6380,1931)),
	Polygon(Point(8202,1731),Point(9144,1748),Point(9141,1834),Point(8922,2164),Point(8206,2015),Point(8229,1872)),
	Polygon(Point(9603,1802),Point(10622,1796),Point(10688,1976),Point(10595,2177),Point(10246,2183),Point(9856,2368),Point(9445,2387),Point(9474,2118),Point(9562,1944)),
	Polygon(Point(11222,1931),Point(11463,2002),Point(11755,2536),Point(11768,2764),Point(11549,2970),Point(10991,3309),Point(10706,3157),Point(10630,3001),Point(10900,2649),Point(11025,2378),Point(11116,2087)),
	Polygon(Point(10270,2685),Point(9861,2720),Point(9286,2857),Point(9098,2817),Point(9024,2670),Point(8710,2578),Point(8658,2644),Point(8578,2865),Point(8261,2908),Point(8140,2740),Point(7978,2405),Point(7795,2434),Point(7632,2667),Point(7666,3181),Point(8043,3126),Point(8695,3263),Point(8964,3428),Point(9499,3113),Point(10143,2940),Point(10283,2812)),
	Polygon(Point(8507,5783),Point(8366,5803),Point(7800,6050),Point(7353,6418),Point(7278,6625),Point(7380,6668),Point(7624,6531),Point(8075,6169),Point(8488,5882)),
	Polygon(Point(13224,10018),Point(13064,9882),Point(12811,9930),Point(12331,9976),Point(11792,10103),Point(11201,10321),Point(11050,10504),Point(11095,10593),Point(11297,10583),Point(11414,10466),Point(11857,10332),Point(12380,10212),Point(12943,10184),Point(13190,10115),Point(13192,9995)),
	Polygon(Point(10442,11085),Point(10228,11164),Point(9977,11835),Point(9864,12429),Point(9783,13039),Point(9906,13253),Point(10081,13066),Point(10002,12789),Point(10048,12454),Point(10184,11917),Point(10425,11414),Point(10478,11177),Point(10438,11094),Point(10230,11201),Point(10152,11425)),
	-- Enemy Jungle
		--Red
		Polygon(Point(8636,12051),Point(8937,11455),Point(9258,11481),Point(9425,12119),Point(9380,13072),Point(8951,13079),Point(9019,12516),Point(8964,12335),Point(8631,12110)),
		Polygon(Point(8303,10445),Point(8415,10435),Point(8682,10932),Point(8270,11649),Point(8066,11756),Point(7879,11774),Point(7660,11645),Point(7691,11390),Point(8208,11074),Point(8202,10591),Point(8266,10476)),
		Polygon(Point(6998,11243),Point(6811,11083),Point(6793,10631),Point(7074,10533),Point(7421,10712),Point(7434,10869),Point(7654,10954),Point(7774,10389),Point(7285,10177),Point(6339,10156),Point(6266,10912),Point(6607,11334),Point(6855,11424),Point(6924,11404)),
		--Blue
		Polygon(Point(10832,5579),Point(11158,5753),Point(11185,5916),Point(10991,6242),Point(11021,6544),Point(10941,6801),Point(10658,6942),Point(10705,7153),Point(11067,7272),Point(11504,7181),Point(11672,7303),Point(11589,7481),Point(10460,7433),Point(10238,7195),Point(10431,6748),Point(10343,6336),Point(10022,6096),Point(10480,5844),Point(10709,5722)),
		--Baron
		Polygon(Point(7382,8051),Point(7572,8187),Point(6986,8779),Point(6697,9011),Point(6353,9100),Point(6349,9016),Point(7027,8505),Point(7314,8120)),
		Polygon(Point(5973,9470),Point(6145,9620),Point(5772,10051),Point(5789,10447),Point(5678,10825),Point(5460,11115),Point(5198,11354),Point(4633,11564),Point(4410,11273),Point(3914,11194),Point(3819,10989),Point(3869,10679),Point(4393,10191),Point(4532,10253),Point(4400,10521),Point(4624,10877),Point(5074,10983),Point(5480,10688),Point(5507,10424),Point(5131,9889),Point(4925,9961),Point(4877,9836),Point(5423,9586),Point(5758,9478)),
		Polygon(Point(3823,11580),Point(4140,11731),Point(4188,11990),Point(3888,12321),Point(3606,12839),Point(3201,12793),Point(3024,12595),Point(3076,12178),Point(3118,11934),Point(3491,11707)),
		--Chicken
		Polygon(Point(7974,8784),Point(8952,9585),Point(8855,9674),Point(8545,9544),Point(8340,9645),Point(8320,10079),Point(8131,10069),Point(8118,9630),Point(8012,9270),Point(7636,9298),Point(7619,9652),Point(7350,9639),Point(7122,9406),Point(7404,9091),Point(7830,8825)),
		Polygon(Point(9226,10036),Point(9988,10637),Point(9700,11008),Point(9489,11131),Point(9153,11140),Point(9138,10814),Point(8766,10194),Point(8782,10048),Point(8902,10001)),
		--Wolfs
		Polygon(Point(11825,7830),Point(12011,7827),Point(12068,8306),Point(11981,8961),Point(11725,8924),Point(11785,9435),Point(10728,9813),Point(10338,9599),Point(9996,9119),Point(10230,9072),Point(10820,9213),Point(11348,8993),Point(11768,8457),Point(11810,8005)),
		Polygon(Point(10346,7925),Point(10623,7806),Point(10984,7788),Point(11366,7960),Point(11362,8178),Point(11260,8275),Point(11088,8094),Point(10928,8096),Point(10704,8304),Point(10828,8608),Point(10720,8745),Point(10487,8569),Point(10311,8367),Point(10282,8163)),
		Polygon(Point(9806,7379),Point(9950,7704),Point(9850,8051),Point(9867,8395),Point(10022,8674),Point(9885,8746),Point(9632,8772),Point(8901,8072),Point(9006,7769),Point(9172,7580),Point(9304,7445)),
		--Botlane Wall
		Polygon(Point(12961,7389),Point(13064,7582),Point(13060,9292),Point(12477,9327),Point(12283,9224),Point(12255,8923),Point(12428,8690),Point(12383,8279),Point(12429,7679),Point(12726,7506)),
		--Midlane River
		Polygon(Point(8579,7544),Point(8274,7257),Point(8536,6867),Point(9142,6497),Point(9589,6392),Point(9948,6639),Point(9926,6852),Point(9110,7083),Point(8589,7544)),
		--Golems
		Polygon(Point(5945,11489),Point(6295,11741),Point(6864,11780),Point(7164,11704),Point(7206,12219),Point(7036,12505),Point(6686,12435),Point(6692,12128),Point(6598,11956),Point(6335,11938),Point(6190,12084),Point(6193,12355),Point(5449,12095),Point(5008,12093),Point(4679,12248),Point(4529,12111),Point(4657,12017),Point(5153,11842),Point(5591,11699)),
		Polygon(Point(6013,12746),Point(6576,12864),Point(6666,13113),Point(6609,13232),Point(5758,13155),Point(5870,12899),Point(5926,12860)),
		Polygon(Point(5317,12499),Point(5379,12777),Point(5228,13119),Point(4742,13123),Point(4499,13167),Point(4224,13120),Point(4201,12808),Point(4359,12740),Point(4790,12712),Point(5089,12557)),
		Polygon(Point(7729,12387),Point(8227,12425),Point(8561,12634),Point(8561,12849),Point(8407,13141),Point(7000,13153),Point(6928,13024),Point(6993,12908),Point(7437,12721),Point(7575,12533)),
		--Frog
		Polygon(Point(12650,5459),Point(13093,5597),Point(13144,6523),Point(13089,6774),Point(12330,7224),Point(12149,7201),Point(12083,6999),Point(12286,6818),Point(12797,6561),Point(12807,6133),Point(12732,5656),Point(12618,5479)),
		Polygon(Point(12226,5075),Point(12303,5254),Point(12264,5551),Point(12315,5901),Point(12318,6205),Point(12107,6427),Point(11732,6552),Point(11486,6364),Point(11595,6205),Point(11939,5946),Point(12055,5670),Point(12018,5329),Point(12103,5156)),
		--Botlane Pyramid
		Polygon(Point(11533,5686),Point(11358,5368),Point(11353,5108),Point(11467,4935),Point(11936,4171),Point(12044,3617),Point(12234,3389),Point(12633,3234),Point(12850,3376),Point(12965,3594),Point(13023,3894),Point(13032,5107),Point(12917,5121),Point(12603,4829),Point(12495,4503),Point(12126,4516),Point(11546,5280),Point(11584,5546)),
		--
	-- My Jungle
		-- Red
		Polygon(Point(7841,3600),Point(8030,3513),Point(8295,3621),Point(8511,3871),Point(8642,4479),Point(8502,4721),Point(8093,4779),Point(7560,4712),Point(7111,4505),Point(7100,4192),Point(7211,4016),Point(7441,4066),Point(7592,4260),Point(7985,4291),Point(8090,3988),Point(7899,3790),Point(7828,3620)),
		-- Drake
		Polygon(Point(10329,3275),Point(10676,3753),Point(10832,3684),Point(10957,3939),Point(10851,4328),Point(10377,4764),Point(10294,4636),Point(10384,4274),Point(10086,3890),Point(9566,3918),Point(9229,4430),Point(9501,4880),Point(9974,4964),Point(9994,5099),Point(9568,5193),Point(9347,5375),Point(8897,5468),Point(8663,5355),Point(8721,5095),Point(9093,4773),Point(9029,4420),Point(9126,3937),Point(9743,3419),Point(10072,3274)),
		--Blue
		Polygon(Point(3357,7475),Point(4311,7483),Point(4568,7671),Point(4307,8378),Point(4721,8789),Point(4692,8878),Point(4307,9001),Point(3908,9406),Point(3707,8890),Point(3866,8660),Point(3796,8162),Point(4122,8021),Point(4176,7827),Point(4046,7632),Point(3743,7643),Point(3410,7713),Point(3206,7650),Point(3206,7536)),
		Polygon(Point(6274,7250),Point(6433,7263),Point(6640,7450),Point(6298,8029),Point(5637,8419),Point(5366,8526),Point(5084,8420),Point(4836,8096),Point(5076,7990),Point(5489,8015),Point(5744,7875),Point(6232,7357)),
		Polygon(Point(1774,5598),Point(2401,5556),Point(2600,5742),Point(2602,5900),Point(2383,6076),Point(2395,6766),Point(2438,7163),Point(1825,7540),Point(1751,6642),Point(1764,6056)),
		--Frog
		Polygon(Point(3281,9277),Point(3430,9383),Point(3510,9686),Point(3191,10247),Point(2984,10788),Point(2663,11415),Point(2283,11695),Point(2034,11578),Point(1837,11138),Point(1823,10486),Point(1817,9862),Point(2188,9989),Point(2369,10389),Point(2650,10470),Point(2903,10368),Point(3140,9952),Point(3280,9460),Point(3241,9307)),
		Polygon(Point(2640,7666),Point(2713,7918),Point(2467,8126),Point(2101,8204),Point(1947,8378),Point(1961,8819),Point(2247,9393),Point(2158,9487),Point(1730,9283),Point(1697,8599),Point(1740,8115),Point(2204,7860),Point(2417,7714)),
		Polygon(Point(2992,8403),Point(3321,8522),Point(3213,8698),Point(2913,9019),Point(2743,9616),Point(2627,9509),Point(2516,8845),Point(2572,8605),Point(2827,8457)),
		--Wolfs
		Polygon(Point(3007,5405),Point(3452,5350),Point(3932,5196),Point(4143,5082),Point(4842,5799),Point(4655,5848),Point(4433,5940),Point(4179,5797),Point(3870,5795),Point(3419,5998),Point(3004,6607),Point(3038,7054),Point(2899,7060),Point(2802,6449),Point(2857,6323),Point(3059,6168),Point(3139,5920)),
		Polygon(Point(4109,6146),Point(4481,6425),Point(4531,6759),Point(4416,6973),Point(3688,7050),Point(3487,6805),Point(3679,6747),Point(3915,6711),Point(4066,6538),Point(4113,6397),Point(3961,6247)),
		Polygon(Point(5192,6147),Point(5860,6730),Point(5909,6985),Point(5656,7346),Point(5283,7521),Point(4968,7486),Point(4838,7265),Point(4974,7041),Point(4954,6439),Point(4818,6245),Point(5016,6154)),
		--
	--
	}

-- Code ------------------------------------------------------------------------

function fileExists(name)
	local f = io.open(name, "r") if f ~= nil then io.close(f) return true else return false end
end

function los(x0, y0, x1, y1, callback)
	local sx,sy,dx,dy

	if x0 < x1 then
		sx = 1
		dx = x1 - x0
	else
		sx = -1
		dx = x0 - x1
	end

	if y0 < y1 then
		sy = 1
		dy = y1 - y0
	else
		sy = -1
		dy = y0 - y1
	end

	local err, e2 = dx-dy, nil

	if not callback(x0, y0) then return false end

	while not(x0 == x1 and y0 == y1) do
		e2 = err + err
		if e2 > -dy then
			err = err - dy
			x0  = x0 + sx
		end

		if e2 < dx then
			err = err + dx
			y0  = y0 + sy
		end

		if not callback(x0, y0) then return false end
	end

	return true
end

function line(x0, y0, x1, y1, callback)
	local points = {}
	local count = 0

	local result = los(x0, y0, x1, y1, function(x,y)
		if callback and not callback(x, y) then return false end

		count = count + 1
		points[count] = {x, y}

		return true
	end)

	return points, result
end

class "SpatialHashMap" -- {
	function SpatialHashMap:__init(spatialObjects, intervalSize, cacheId)
		if intervalSize == nil then intervalSize = 400 end

		self.hashTables = {}
		self.intervalSize = intervalSize
		self.cacheId = cacheId

		if cacheId then
			self.tempCachedData = {}
		end

		self:loadObjects(spatialObjects)
	end

	function SpatialHashMap:loadObjects(spatialObjects)
		if self.cacheId and fileExists(SCRIPT_PATH .. "MapPosition_" .. self.cacheId .. ".lua") then
			_G.s = spatialObjects require ("MapPosition_" .. self.cacheId)

			self.hashTables = _G.h return
		end
			
		for i, spatialObject in ipairs(spatialObjects) do
			local addResult = self:add(spatialObject)

			if self.cacheId then
				self:cacheObject(addResult, i)
			end
		end
		for i, spatialObject in pairs(spatialObjects) do
			local addResult = self:add(spatialObject)

			if self.cacheId then
				self:cacheObject(addResult, i)
			end
		end

		if self.cacheId then
			self:writeCache()
		end
	end

	function SpatialHashMap:cacheObject(addResult, objectIdentifier)
		for k, v in pairs(addResult) do
			if not self.tempCachedData[k] then
				self.tempCachedData[k] = {objectIdentifier}
			else
				table.insert(self.tempCachedData[k], objectIdentifier)
			end
		end
	end

	function SpatialHashMap:writeCache()
		local res = "_G.h={"
		for a, b in pairs(self.tempCachedData) do
			if res == "_G.h={" then
				res = res .. "[\"" .. a .. "\"]={"
			else
				res = res .. ",[\"" .. a .. "\"]={"
			end

			cols = ""
			for c, d in ipairs(b) do
				if cols == "" then
					if type(d) == "number" then
						cols = cols .. "_G.s[" .. tostring(d) .. "]"
					else
						cols = cols .. "_G.s[\"" .. d .. "\"]"
					end
				else
					if type(d) == "number" then
						cols = cols .. ",_G.s[" .. tostring(d) .. "]"
					else
						cols = cols .. ",_G.s[\"" .. d .. "\"]"
					end
				end
			end
			res = res .. cols .. "}"
		end
		res = res .. "}"
		local file, error = assert(io.open(SCRIPT_PATH .. "MapPosition_" .. self.cacheId .. ".lua", "w+")) 
		if error then 
			return error 
		end 
		file:write(res) 
		file:close()
	end

	function SpatialHashMap:add(spatialObject)
		if spatialObject:__type() == "Circle" then
			leftX = spatialObject.point.x - spatialObject.radius
			rightX = spatialObject.point.x + spatialObject.radius
			bottomY = spatialObject.point.y - spatialObject.radius
			topY = spatialObject.point.y + spatialObject.radius
		else
			leftX = math.huge
			rightX = -math.huge
			bottomY = math.huge
			topY = -math.huge
			for i, point in ipairs(spatialObject:__getPoints()) do
				leftX = math.min(leftX, point.x)
				rightX = math.max(rightX, point.x)
				bottomY = math.min(bottomY, point.y)
				topY = math.max(topY, point.y)
			end
		end

		foundHashCodes = {}
		if spatialObject:__type() == "Circle" then
			for x = math.floor(leftX / self.intervalSize), math.floor(rightX / self.intervalSize), 1 do
				for y = math.floor(bottomY / self.intervalSize), math.floor(topY / self.intervalSize), 1 do
					hashCode = self:calculateHashCode(Point(x * self.intervalSize, y * self.intervalSize))
					if self.hashTables[hashCode] == nil then
						self.hashTables[hashCode] = {}
					end

					if foundHashCodes[hashCode] == nil then
						self.hashTables[hashCode][tostring(spatialObject.uniqueId)] = spatialObject
						foundHashCodes[hashCode] = hashCode
					end
				end
			end
		else
			for i, lineSegment in ipairs(spatialObject:__getLineSegments()) do
				for x = math.floor(leftX / self.intervalSize), math.floor(rightX / self.intervalSize), 1 do
					for y = math.floor(bottomY / self.intervalSize), math.floor(topY / self.intervalSize), 1 do
						local quadraliterate = Polygon(Point(x * self.intervalSize, y * self.intervalSize), Point(x * self.intervalSize, y * self.intervalSize + self.intervalSize), Point(x * self.intervalSize + self.intervalSize, y * self.intervalSize + self.intervalSize), Point(x * self.intervalSize + self.intervalSize, y * self.intervalSize))

						hashCode = self:calculateHashCode(quadraliterate.points[1])
						if (quadraliterate:__intersects(lineSegment) or spatialObject:__contains(quadraliterate.points[1]) or quadraliterate:__contains(lineSegment)) and foundHashCodes[hashCode] == nil then
							if self.hashTables[hashCode] == nil then
								self.hashTables[hashCode] = {}
							end

							self.hashTables[hashCode][tostring(spatialObject.uniqueId)] = spatialObject
							foundHashCodes[hashCode] = hashCode
						end
					end
				end
			end
		end
		return foundHashCodes
	end

	function SpatialHashMap:remove(spatialObject)
		leftX = math.huge
		rightX = -math.huge
		bottomY = math.huge
		topY = -math.huge
		for i, point in ipairs(spatialObject:__getPoints()) do
			leftX = math.min(leftX, point.x)
			rightX = math.max(rightX, point.x)
			bottomY = math.min(bottomY, point.y)
			topY = math.max(topY, point.y)
		end

		foundHashCodes = {}
		for i, lineSegment in ipairs(spatialObject:__getLineSegments()) do
			for x = math.floor(leftX / self.intervalSize), math.floor(rightX / self.intervalSize), 1 do
				for y = math.floor(bottomY / self.intervalSize), math.floor(topY / self.intervalSize), 1 do
					local quadraliterate = Polygon(Point(x * self.intervalSize, y * self.intervalSize), Point(x * self.intervalSize, y * self.intervalSize + self.intervalSize), Point(x * self.intervalSize + self.intervalSize, y * self.intervalSize + self.intervalSize), Point(x * self.intervalSize + self.intervalSize, y * self.intervalSize))

					hashCode = self:calculateHashCode(quadraliterate.points[1])
					if (quadraliterate:__intersects(lineSegment) or spatialObject:__contains(quadraliterate.points[1]) or quadraliterate:__contains(lineSegment)) and foundHashCodes[hashCode] == nil then
						self.hashTables[hashCode][tostring(spatialObject.uniqueId)] = nil

						foundHashCodes[hashCode] = hashCode
					end
				end
			end
		end
	end

	function SpatialHashMap:calculateHashCode(point)
		return tostring(math.floor(point.x / self.intervalSize)) .. "-" .. tostring(math.floor(point.y / self.intervalSize))
	end

	function SpatialHashMap:getSpatialObjects(referencePoint, range)
		if referencePoint == nil then
			local result = {}

			for hashCode, hashTable in pairs(self.hashTables) do
				for uniqueId, spatialObject in pairs(hashTable) do
					result[uniqueId] = spatialObject
				end
			end

			return result
		else
			if range == nil then range = 0 else range = math.ceil(range/self.intervalSize) end

			local result = {}

			hashCode = self:calculateHashCode(referencePoint)
			if self.hashTables[hashCode] ~= nil then
				for uniqueId, spatialObject in pairs(self.hashTables[hashCode]) do
					result[uniqueId] = spatialObject
				end
			end
			for i = 1, range, 1 do
				for k, directionVector in ipairs({Point(-1, -1), Point(-1, 0), Point(-1, 1), Point(0, -1), Point(0, 1), Point(1, -1), Point(1, 0), Point(1, 1)}) do
					hashCode = self:calculateHashCode(referencePoint + directionVector * i * self.intervalSize)
					if self.hashTables[hashCode] ~= nil then
						for uniqueId, spatialObject in pairs(self.hashTables[hashCode]) do
							result[uniqueId] = spatialObject
						end
					end
				end
    		end

			return result
		end
	end
-- }

class "MapPosition" -- {
	function MapPosition:__init()
		self.wallSpatialHashMap = SpatialHashMap(walls, 400, "walls_1_1")
	end

	-- Wall Functions ---------------------------------------------------------

	function MapPosition:inWall(point)
		for wallId, wall in pairs(self.wallSpatialHashMap:getSpatialObjects(point)) do
			if wall:__contains(point) then
				return true
			end
		end

		return false
	end

	function MapPosition:intersectsWall(pointOrLinesegment)
		local lineSegment = (pointOrLinesegment:__type() == "Point") and LineSegment(Point(myHero.x, myHero.z), pointOrLinesegment) or pointOrLinesegment

		return not los(math.floor(lineSegment.points[1].x / self.wallSpatialHashMap.intervalSize), math.floor(lineSegment.points[1].y / self.wallSpatialHashMap.intervalSize), math.floor(lineSegment.points[2].x / self.wallSpatialHashMap.intervalSize), math.floor(lineSegment.points[2].y / self.wallSpatialHashMap.intervalSize), function(x, y)
			for wallId, wall in pairs(self.wallSpatialHashMap:getSpatialObjects(Point(x * self.wallSpatialHashMap.intervalSize, y * self.wallSpatialHashMap.intervalSize))) do
				if wall:__intersects(lineSegment) then
					return false
				end
			end

			return true
		end)
	end

	-- River Positions --------------------------------------------------------

	function MapPosition:inRiver(unit)
		return MapPosition:inTopRiver(unit) or MapPosition:inBottomRiver(unit)
	end

	function MapPosition:inTopRiver(unit)
		return regions["topOuterRiver"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inTopInnerRiver(unit)
		return regions["topInnerRiver"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inTopOuterRiver(unit)
		return MapPosition:inTopRiver(unit) and not MapPosition:inTopInnerRiver(unit)
	end

	function MapPosition:inBottomRiver(unit)
		return regions["bottomOuterRiver"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inBottomInnerRiver(unit)
		return regions["bottomInnerRiver"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inBottomOuterRiver(unit)
		return MapPosition:inBottomRiver(unit) and not MapPosition:inBottomInnerRiver(unit)
	end

	function MapPosition:inOuterRiver(unit)
		return MapPosition:inTopOuterRiver(unit) or MapPosition:inBottomOuterRiver(unit)
	end

	function MapPosition:inInnerRiver(unit)
		return MapPosition:inTopInnerRiver(unit) or MapPosition:inBottomInnerRiver(unit)
	end

	-- Base Positions ---------------------------------------------------------

	function MapPosition:inBase(unit)
		return MapPosition:inLeftBase(unit) or MapPosition:inRightBase(unit)
	end

	function MapPosition:inLeftBase(unit)
		return regions["inLeftBase"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inRightBase(unit)
		return regions["inRightBase"]:__contains(Point(unit.x, unit.z))
	end

	-- Lane Positions ---------------------------------------------------------

	function MapPosition:onLane(unit)
		return MapPosition:onTopLane(unit) or MapPosition:onMidLane(unit) or MapPosition:onBotLane(unit)
	end

	function MapPosition:onTopLane(unit)
		unitPoint = Point(unit.x, unit.z)

		return regions["leftTopLane"]:contains(unitPoint) or regions["centerTopLane"]:contains(unitPoint) or regions["rightTopLane"]:__contains(unitPoint)
	end

	function MapPosition:onMidLane(unit)
		unitPoint = Point(unit.x, unit.z)

		return regions["leftMidLane"]:contains(unitPoint) or regions["centerMidLane"]:contains(unitPoint) or regions["rightMidLane"]:__contains(unitPoint)
	end

	function MapPosition:onBotLane(unit)
		unitPoint = Point(unit.x, unit.z)

		return regions["leftBotLane"]:contains(unitPoint) or regions["centerBotLane"]:contains(unitPoint) or regions["rightBotLane"]:__contains(unitPoint)
	end

	-- Jungle Positions -------------------------------------------------------

	function MapPosition:inJungle(unit)
		return MapPosition:inLeftJungle(unit) or MapPosition:inRightJungle(unit)
	end

	function MapPosition:inOuterJungle(unit)
		return MapPosition:inLeftOuterJungle(unit) or MapPosition:inRightOuterJungle(unit)
	end

	function MapPosition:inInnerJungle(unit)
		return MapPosition:inLeftInnerJungle(unit) or MapPosition:inRightInnerJungle(unit)
	end

	function MapPosition:inLeftJungle(unit)
		return MapPosition:inTopLeftJungle(unit) or MapPosition:inBottomLeftJungle(unit)
	end

	function MapPosition:inLeftOuterJungle(unit)
		return MapPosition:inTopLeftOuterJungle(unit) or MapPosition:inBottomLeftOuterJungle(unit)
	end

	function MapPosition:inLeftInnerJungle(unit)
		return MapPosition:inTopLeftInnerJungle(unit) or MapPosition:inBottomLeftInnerJungle(unit)
	end

	function MapPosition:inTopLeftJungle(unit)
		return regions["topLeftOuterJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inTopLeftOuterJungle(unit)
		return MapPosition:inTopLeftJungle(unit) and not MapPosition:inTopLeftInnerJungle(unit)
	end

	function MapPosition:inTopLeftInnerJungle(unit)
		return regions["topLeftInnerJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inBottomLeftJungle(unit)
		return regions["bottomLeftOuterJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inBottomLeftOuterJungle(unit)
		return MapPosition:inBottomLeftJungle(unit) and not MapPosition:inBottomLeftInnerJungle(unit)
	end

	function MapPosition:inBottomLeftInnerJungle(unit)
		return regions["bottomLeftInnerJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inRightJungle(unit)
		return MapPosition:inTopRightJungle(unit) or MapPosition:inBottomRightJungle(unit)
	end

	function MapPosition:inRightOuterJungle(unit)
		return MapPosition:inTopRightOuterJungle(unit) or MapPosition:inBottomRightOuterJungle(unit)
	end

	function MapPosition:inRightInnerJungle(unit)
		return MapPosition:inTopRightInnerJungle(unit) or MapPosition:inBottomRightInnerJungle(unit)
	end

	function MapPosition:inTopRightJungle(unit)
		return regions["topRightOuterJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inTopRightOuterJungle(unit)
		return MapPosition:inTopRightJungle(unit) and not MapPosition:inTopRightInnerJungle(unit)
	end

	function MapPosition:inTopRightInnerJungle(unit)
		return regions["topRightInnerJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inBottomRightJungle(unit)
		return regions["bottomRightOuterJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inBottomRightOuterJungle(unit)
		return MapPosition:inBottomRightJungle(unit) and not MapPosition:inBottomRightInnerJungle(unit)
	end

	function MapPosition:inBottomRightInnerJungle(unit)
		return regions["bottomRightInnerJungle"]:__contains(Point(unit.x, unit.z))
	end

	function MapPosition:inTopJungle(unit)
		return MapPosition:inTopLeftJungle(unit) or MapPosition:inTopRightJungle(unit)
	end

	function MapPosition:inTopOuterJungle(unit)
		return MapPosition:inTopLeftOuterJungle(unit) or MapPosition:inTopRightOuterJungle(unit)
	end

	function MapPosition:inTopInnerJungle(unit)
		return MapPosition:inTopLeftInnerJungle(unit) or MapPosition:inTopRightInnerJungle(unit)
	end

	function MapPosition:inBottomJungle(unit)
		return MapPosition:inBottomLeftJungle(unit) or MapPosition:inBottomRightJungle(unit)
	end

	function MapPosition:inBottomOuterJungle(unit)
		return MapPosition:inBottomLeftOuterJungle(unit) or MapPosition:inBottomRightOuterJungle(unit)
	end

	function MapPosition:inBottomInnerJungle(unit)
		return MapPosition:inBottomLeftInnerJungle(unit) or MapPosition:inBottomRightInnerJungle(unit)
	end
-- }
