/*
	This file is part of ppather.

	PPather is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	PPather is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with ppather.  If not, see <http://www.gnu.org/licenses/>.

	Copyright Pontus Borg 2008
	Ported to Objective-C by wjlafrance@gmail.com (in progress)
*/

#import "MpqTriangleSupplier.h"

@implementation MpqTriangleSupplier

- (id) init {


	// original pather detected this from registry, rather difficult on mac
	gamePath = @"/Applications/World of WarCraft/Data";
	PGLog(@"Game directory (hardcoded): %@", gamePath);

	archiveNames = [NSMutableArray arrayWithObjects:
			[NSString stringWithFormat:@"%@/%@", gamePath, @"common.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"common-2.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"expansion.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"lichking.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"patch.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enUS/patch-enUS.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enGB/patch-enGB.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enUS/lichking-locale-enUS.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enGB/lichking-locale-enGB.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enUS/locale-enUS.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enGB/locale-enGB.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enUS/expansion-locale-enUS.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enGB/expansion-locale-enGB.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enUS/base-enUS.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enGB/base-enGB.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enUS/backup-enUS.MPQ"],
			[NSString stringWithFormat:@"%@/%@", gamePath, @"enGB/backup-enGB.MPQ"],
			nil];
	
	[MpqOneshotExtractor extractFile:@"DBFilesClient\\AreaTable.dbc"
			fromMpqList:archiveNames
			toFile:[NSString stringWithFormat:@"%@/%@/%@",
					NSHomeDirectory(), @"pather-temp",
					@"DBFilesClient/AreaTable.dbc"]];
	
	//areaDbc = [[DBC alloc] init];
	
	
	#warning MpqTriangleSupplier not finished porting

	/*
	modelmanager = new ModelManager(archive, 80);
	wmomanager = new WMOManager(archive, modelmanager, 30);
	*/


	return self;
}

/*
            archive.ExtractFile("DBFilesClient\\AreaTable.dbc", Application.StartupPath + "\\Temps\\AreaTable.dbc");
			DBC areas = new DBC();
            DBCFile af = new DBCFile(Application.StartupPath + "\\Temps\\AreaTable.dbc", areas);
			for (int i = 0; i < areas.recordCount; i++)
			{
				int AreaID = (int)areas.GetUint(i, 0);
				int WorldID = (int)areas.GetUint(i, 1);
				int Parent = (int)areas.GetUint(i, 2);
				string Name = areas.GetString(i, 11);

				areaIdToName.Add(AreaID, Name);


				if (WorldID != 0 && WorldID != 1 && WorldID != 530)
				{
					////   Console.WriteLine(String.Format("{0,4} {1,3} {2,3} {3}", AreaID, WorldID, Parent, Name));
				}
				//0 	 uint 	 AreaID
				//1 	uint 	Continent (refers to a WorldID)
				//2 	uint 	Region (refers to an AreaID)
			}

			for (int i = 0; i < areas.recordCount; i++)
			{
				int AreaID = (int)areas.GetUint(i, 0);
				int WorldID = (int)areas.GetUint(i, 1);
				int Parent = (int)areas.GetUint(i, 2);
				string Name = areas.GetString(i, 11);

				string TotalName = "";
				//areaIdToName.Add(AreaID, Name);
				//areaIdParent.Add(AreaID, Parent);
				string ParentName = "";
				if (!areaIdToName.TryGetValue(Parent, out ParentName))
				{
					TotalName = ":" + Name;
				}
				else
					TotalName = Name + ":" + ParentName;
				try
				{
					zoneToMapId.Add(TotalName, WorldID);
					//Console.WriteLine(TotalName + " => " + WorldID);
				}
				catch
				{
					int id;
					zoneToMapId.TryGetValue(TotalName, out id);
					////  Console.WriteLine("Duplicate: " + TotalName + " " + WorldID +" " + id);
				}
				//0 	 uint 	 AreaID
				//1 	uint 	Continent (refers to a WorldID)
				//2 	uint 	Region (refers to an AreaID)
			}
		}


}
		string continentFile;

		StormDll.ArchiveSet archive;

		//TriangleSet global_triangles = new TriangleSet();

		WDT wdt;
		WDTFile wdtf;
		ModelManager modelmanager;
		WMOManager wmomanager;


		Dictionary<String, int> zoneToMapId = new Dictionary<string, int>();
		Dictionary<int, String> mapIdToFile = new Dictionary<int, string>();

		Dictionary<int, String> areaIdToName = new Dictionary<int, string>();

		public override void Close()
		{
			archive.Close();
			wdt = null;
			wdtf = null;
			modelmanager = null;
			wmomanager = null;
			zoneToMapId = null;
			mapIdToFile = null;
			areaIdToName = null;
			archive = null;
			base.Close();
		}

		public void SetContinent(string continent)
		{
			continentFile = continent;


			wdt = new WDT();

			wdtf = new WDTFile(archive, continentFile, wdt, wmomanager, modelmanager);
			if (!wdtf.loaded)
            {
                wdt = null; // bad
                throw new Exception("Failed to set continent to: " + continent);
            }
			else
			{

				// Console.WriteLine("  global Objects " + wdt.gwmois.Count + " Models " + wdt.gwmois.Count);
				//global_triangles.color = new float[3] { 0.8f, 0.8f, 1.0f };
			}

		}



		public string SetZone(string zone)
		{
			int continentID;

			if (!zoneToMapId.TryGetValue(zone, out continentID))
			{
				int colon = zone.IndexOf(":");
				if (colon == -1)
					return null;
				zone = zone.Substring(colon);
				if (!zoneToMapId.TryGetValue(zone, out continentID))
				{
					return null;
				}
			}

            archive.ExtractFile("DBFilesClient\\Map.dbc", Application.StartupPath + "\\Temps\\Map.dbc");
			DBC maps = new DBC();
            DBCFile mf = new DBCFile(Application.StartupPath + "\\Temps\\Map.dbc", maps);


			for (int i = 0; i < maps.recordCount; i++)
			{
				int mapID = maps.GetInt(i, 0);
				// Console.WriteLine("   ID:" + maps.GetInt(i, 0));                
				// Console.WriteLine(" File: " + maps.GetString(i, 1));
				// Console.WriteLine(" Name: " + maps.GetString(i, 4)); // the file!!!

				if (mapID == continentID) // file == continentFile)
				{
					//  Console.WriteLine(String.Format("{0,4} {1}", mapID, maps.GetString(i, 1)));
					string file = maps.GetString(i, 1);
					SetContinent(file);
					return continentFile;
				}
			}
			if (wdt == null)
			{
				return "Failed to open file files for continent ID" + continentID;
			}
			return null;
		}




		private void GetChunkData(TriangleCollection triangles, int chunk_x, int chunk_y, SparseMatrix3D<WMO> instances)
		{
			if (chunk_x < 0)
				return;
			if (chunk_y < 0)
				return;
			if (chunk_x > 63)
				return;
			if (chunk_y > 63)
				return;


			if (triangles == null)
				return;

			if (wdtf == null)
				return;
			if (wdt == null)
				return;
			wdtf.LoadMapTile(chunk_x, chunk_y);


			MapTile t = wdt.maptiles[chunk_x, chunk_y];
			if (t != null)
			{
				//Console.Write(" render"); 
				// Map tiles                
				for (int ci = 0; ci < 16; ci++)
				{
					for (int cj = 0; cj < 16; cj++)
					{
						MapChunk c = t.chunks[ci, cj];
						if (c != null)
							AddTriangles(triangles, c);
					}
				}

				// World objects

				foreach (WMOInstance wi in t.wmois)
				{
					if (wi != null && wi.wmo != null)
					{
						String fn = wi.wmo.fileName;
						int last = fn.LastIndexOf('\\');
						fn = fn.Substring(last + 1);
						// Console.WriteLine("    wmo: " + fn + " at " + wi.pos);
						if (fn != null)
						{

							WMO old = instances.Get((int)wi.pos.x, (int)wi.pos.y, (int)wi.pos.z);
							if (old == wi.wmo)
							{
								//Console.WriteLine("Already got " + fn);
							}
							else
							{
								instances.Set((int)wi.pos.x, (int)wi.pos.y, (int)wi.pos.z, wi.wmo);
								AddTriangles(triangles, wi);

							}
						}
					}
				}

				foreach (ModelInstance mi in t.modelis)
				{
					if (mi != null && mi.model != null)
					{
						String fn = mi.model.fileName;
						int last = fn.LastIndexOf('\\');
						// fn = fn.Substring(last + 1);
						//Console.WriteLine("    wmi: " + fn + " at " + mi.pos);
						AddTriangles(triangles, mi);

						//Console.WriteLine("    model: " + fn);
					}
				}



				Console.WriteLine("wee");

			}
			Console.WriteLine(" done");
			wdt.maptiles[chunk_x, chunk_y] = null; // clear it atain
			//myChunk.triangles.ClearVertexMatrix(); // not needed anymore
			//return myChunk;
		}

		private void GetChunkCoord(float x, float y, out int chunk_x, out int chunk_y)
		{
			// yeah, this is ugly. But safe
			for (chunk_x = 0; chunk_x < 64; chunk_x++)
			{
				float max_y = ChunkReader.ZEROPOINT - (float)(chunk_x) * ChunkReader.TILESIZE;
				float min_y = max_y - ChunkReader.TILESIZE;
				if (y >= min_y - 0.1f && y < max_y + 0.1f)
					break;
			}
			for (chunk_y = 0; chunk_y < 64; chunk_y++)
			{
				float max_x = ChunkReader.ZEROPOINT - (float)(chunk_y) * ChunkReader.TILESIZE;
				float min_x = max_x - ChunkReader.TILESIZE;
				if (x >= min_x - 0.1f && x < max_x + 0.1f)
					break;
			}
			if (chunk_y == 64 || chunk_x == 64)
			{
				Console.WriteLine(x + " " + y + " is at " + chunk_x + " " + chunk_y);
				//GetChunkCoord(x, y, out chunk_x, out chunk_y); 
			}
		}

		public override void GetTriangles(TriangleCollection to, float min_x, float min_y, float max_x, float max_y)
		{
			//Console.WriteLine("TotalMemory " + System.GC.GetTotalMemory(false)/(1024*1024) + " MB");
			foreach (WMOInstance wi in wdt.gwmois)
			{
				AddTriangles(to, wi);
			}
			SparseMatrix3D<WMO> instances = new SparseMatrix3D<WMO>();
			for (float x = min_x; x < max_x; x += ChunkReader.TILESIZE)
			{
				for (float y = min_y; y < max_y; y += ChunkReader.TILESIZE)
				{
					int chunk_x, chunk_y;
					GetChunkCoord(x, y, out chunk_x, out chunk_y);
					//ChunkData d = 
					GetChunkData(to, chunk_x, chunk_y, instances);

					//to.AddAllTrianglesFrom(d.triangles); 
				}
			}


		}

		void AddTriangles(TriangleCollection s, MapChunk c)
		{
			int[,] vertices = new int[9, 9];
			int[,] verticesMid = new int[8, 8];

			for (int row = 0; row < 9; row++)
				for (int col = 0; col < 9; col++)
				{
					float x, y, z;
					ChunkGetCoordForPoint(c, row, col, out x, out y, out z);
					int index = s.AddVertex(x, y, z);
					vertices[row, col] = index;
				}

			for (int row = 0; row < 8; row++)
				for (int col = 0; col < 8; col++)
				{
					float x, y, z;
					ChunkGetCoordForMiddlePoint(c, row, col, out x, out y, out z);
					int index = s.AddVertex(x, y, z);
					verticesMid[row, col] = index;
				}
			for (int row = 0; row < 8; row++)
			{
				for (int col = 0; col < 8; col++)
				{
					if (!c.isHole(col, row))
					{
						int v0 = vertices[row, col];
						int v1 = vertices[row + 1, col];
						int v2 = vertices[row + 1, col + 1];
						int v3 = vertices[row, col + 1];
						int vMid = verticesMid[row, col];

						s.AddTriangle(v0, v1, vMid);
						s.AddTriangle(v1, v2, vMid);
						s.AddTriangle(v2, v3, vMid);
						s.AddTriangle(v3, v0, vMid);

					}
				}
			}

			if (c.haswater)
			{
				// paint the water
				for (int row = 0; row < 9; row++)
					for (int col = 0; col < 9; col++)
					{
						float x, y, z;
						ChunkGetCoordForPoint(c, row, col, out x, out y, out z);
						float height = c.water_height[row, col] - 1.5f;
						int index = s.AddVertex(x, y, height);
						vertices[row, col] = index;
					}
				for (int row = 0; row < 8; row++)
				{
					for (int col = 0; col < 8; col++)
					{
						if (c.water_flags[row, col] != 0xf)
						{
							int v0 = vertices[row, col];
							int v1 = vertices[row + 1, col];
							int v2 = vertices[row + 1, col + 1];
							int v3 = vertices[row, col + 1];

							s.AddTriangle(v0, v1, v3, ChunkedTriangleCollection.TriangleFlagDeepWater);
							s.AddTriangle(v1, v2, v3, ChunkedTriangleCollection.TriangleFlagDeepWater);
						}
					}
				}
			}

		}


		void AddTriangles(TriangleCollection s, WMOInstance wi)
		{
			float dx = wi.pos.x;
			float dy = wi.pos.y;
			float dz = wi.pos.z;

			float dir_x = wi.dir.z;
			float dir_y = wi.dir.y - 90;
			float dir_z = -wi.dir.x;

			Console.WriteLine("modeli: " + dir_x + " " + dir_y + " " + dir_z);
			WMO wmo = wi.wmo;

			foreach (WMOGroup g in wmo.groups)
			{
				int[] vertices = new int[g.nVertices];

				for (int i = 0; i < g.nVertices; i++)
				{
					int off = i * 3;

					float x = g.vertices[off];
					float y = g.vertices[off + 2];
					float z = g.vertices[off + 1];

					rotate(z, y, dir_x, out z, out y);
					rotate(x, y, dir_z, out x, out y);
					rotate(x, z, dir_y, out x, out z);


					float xx = x + dx;
					float yy = y + dy;
					float zz = -z + dz;

					float finalx = ChunkReader.ZEROPOINT - zz;
					float finaly = ChunkReader.ZEROPOINT - xx;
					float finalz = yy;

					vertices[i] = s.AddVertex(finalx, finaly, finalz);
				}
				// Console.WriteLine("nTriangles: " + g.nTriangles); 
				for (int i = 0; i < g.nTriangles; i++)
				{
					//if ((g.materials[i] & 0x1000) != 0)
					{
						int off = i * 3;
						int i0 = vertices[g.triangles[off]];
						int i1 = vertices[g.triangles[off + 1]];
						int i2 = vertices[g.triangles[off + 2]];

						int t = s.AddTriangle(i0, i1, i2, ChunkedTriangleCollection.TriangleFlagObject);
						//if(t != -1) s.SetTriangleExtra(t, g.materials[0], 0, 0); 
					}
				}
			}

			int doodadset = wi.doodadset;


			if (doodadset < wmo.nDoodadSets)
			{
				uint firstDoodad = wmo.doodads[doodadset].firstInstance;
				uint nDoodads = wmo.doodads[doodadset].nInstances;

				for (uint i = 0; i < nDoodads; i++)
				{
					uint d = firstDoodad + i;
					ModelInstance mi = wmo.doodadInstances[d];
					if (mi != null)
					{
						//Console.WriteLine("I got model " + mi.model.fileName + " at " + mi.pos);
						//AddTrianglesGroupDoodads(s, mi, wi.dir, wi.pos, 0.0f); // DOes not work :(
					}
				}
			}

		}


		void AddTrianglesGroupDoodads(TriangleCollection s, ModelInstance mi, Vec3D world_dir, Vec3D world_off, float rot)
		{
			float dx = mi.pos.x;
			float dy = mi.pos.y;
			float dz = mi.pos.z;

			rotate(dx, dz, rot + 90f, out dx, out dz);


			dx += world_off.x;
			dy += world_off.y;
			dz += world_off.z;


			Quaternion q;
			q.x = mi.dir.z;
			q.y = mi.dir.x;
			q.z = mi.dir.y;
			q.w = mi.w;
			Matrix4 rotMatrix = new Matrix4();
			rotMatrix.makeQuaternionRotate(q);


			Model m = mi.model;

			if (m.boundingTriangles == null)
			{

			}
			else
			{

				// We got boiuding stuff, that is better
				int nBoundingVertices = m.boundingVertices.Length / 3;
				int[] vertices = new int[nBoundingVertices];

				for (uint i = 0; i < nBoundingVertices; i++)
				{
					uint off = i * 3;
					float x = m.boundingVertices[off];
					float y = m.boundingVertices[off + 2];
					float z = m.boundingVertices[off + 1];
					x *= mi.sc;
					y *= mi.sc;
					z *= -mi.sc;

					Vector pos;
					pos.x = x;
					pos.y = y;
					pos.z = z;
					Vector new_pos = rotMatrix.mutiply(pos);
					x = pos.x;
					y = pos.y;
					z = pos.z;

					float dir_x = world_dir.z;
					float dir_y = world_dir.y - 90;
					float dir_z = -world_dir.x;

					rotate(z, y, dir_x, out z, out y);
					rotate(x, y, dir_z, out x, out y);
					rotate(x, z, dir_y, out x, out z);

					float xx = x + dx;
					float yy = y + dy;
					float zz = -z + dz;

					float finalx = ChunkReader.ZEROPOINT - zz;
					float finaly = ChunkReader.ZEROPOINT - xx;
					float finalz = yy;
					vertices[i] = s.AddVertex(finalx, finaly, finalz);
				}


				int nBoundingTriangles = m.boundingTriangles.Length / 3;
				for (uint i = 0; i < nBoundingTriangles; i++)
				{
					uint off = i * 3;
					int v0 = vertices[m.boundingTriangles[off]];
					int v1 = vertices[m.boundingTriangles[off + 1]];
					int v2 = vertices[m.boundingTriangles[off + 2]];
					s.AddTriangle(v0, v2, v1, ChunkedTriangleCollection.TriangleFlagModel);
				}

			}
		}

		void AddTriangles(TriangleCollection s, ModelInstance mi)
		{

			float dx = mi.pos.x;
			float dy = mi.pos.y;
			float dz = mi.pos.z;

			float dir_x = mi.dir.z;
			float dir_y = mi.dir.y - 90; // -90 is correct!
			float dir_z = -mi.dir.x;

			Model m = mi.model;
			if (m == null)
				return;

			if (m.boundingTriangles == null)
			{

				// /cry no bouding info, revert to normal vertives
			}
			else
			{
				// We got boiuding stuff, that is better
				int nBoundingVertices = m.boundingVertices.Length / 3;
				int[] vertices = new int[nBoundingVertices];
				for (uint i = 0; i < nBoundingVertices; i++)
				{
					uint off = i * 3;
					float x = m.boundingVertices[off];
					float y = m.boundingVertices[off + 2];
					float z = m.boundingVertices[off + 1];


					rotate(z, y, dir_x, out z, out y);
					rotate(x, y, dir_z, out x, out y);
					rotate(x, z, dir_y, out x, out z);


					x *= mi.sc;
					y *= mi.sc;
					z *= mi.sc;

					float xx = x + dx;
					float yy = y + dy;
					float zz = -z + dz;

					float finalx = ChunkReader.ZEROPOINT - zz;
					float finaly = ChunkReader.ZEROPOINT - xx;
					float finalz = yy;

					vertices[i] = s.AddVertex(finalx, finaly, finalz);
				}


				int nBoundingTriangles = m.boundingTriangles.Length / 3;
				for (uint i = 0; i < nBoundingTriangles; i++)
				{
					uint off = i * 3;
					int v0 = vertices[m.boundingTriangles[off]];
					int v1 = vertices[m.boundingTriangles[off + 1]];
					int v2 = vertices[m.boundingTriangles[off + 2]];
					s.AddTriangle(v0, v1, v2, ChunkedTriangleCollection.TriangleFlagModel);
				}
			}
		}

		static void ChunkGetCoordForPoint(MapChunk c, int row, int col,
										  out float x, out float y, out float z)
		{
			int off = (row * 17 + col) * 3;
			x = ChunkReader.ZEROPOINT - c.vertices[off + 2];
			y = ChunkReader.ZEROPOINT - c.vertices[off];
			z = c.vertices[off + 1];
		}

		static void ChunkGetCoordForMiddlePoint(MapChunk c, int row, int col,
											out float x, out float y, out float z)
		{
			int off = (9 + (row * 17 + col)) * 3;
			x = ChunkReader.ZEROPOINT - c.vertices[off + 2];
			y = ChunkReader.ZEROPOINT - c.vertices[off];
			z = c.vertices[off + 1];
		}







		public static void rotate(float x, float y, float angle, out float nx, out float ny)
		{
			double rot = (angle) / 360.0 * Math.PI * 2;
			float c_y = (float)Math.Cos(rot);
			float s_y = (float)Math.Sin(rot);


			nx = c_y * x - s_y * y;
			ny = s_y * x + c_y * y;
		}



	}*/
@end
