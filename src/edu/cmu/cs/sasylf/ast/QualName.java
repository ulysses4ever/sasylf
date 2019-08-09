package edu.cmu.cs.sasylf.ast;

import java.io.PrintWriter;

import edu.cmu.cs.sasylf.util.ErrorHandler;
import edu.cmu.cs.sasylf.util.Location;

/**
 * A qualified name, used in the SASyLF module system.
 * A qualified name can resolve to:
 * <ul>
 * <li> A SASyLF package, represented by an array of Strings
 * <li> A module either found through the file system or found in the context 
 * <li> A syntax declaration, judgment, rule or theorem in a module
 * </ul>
 */
public class QualName extends Node {
	private final QualName source;
	private final String name;
	
	private Object resolution;
	private int version;
	
	/**
	 * Create a qualified name attached (using ".") to a previous qualified name
	 * @param qn previous qn, may be null
	 * @param loc location of start of this name
	 * @param name string naming entity referred to
	 */
	public QualName(QualName qn, Location loc, String name) {
		super(qn == null ? loc : qn.getLocation(),loc.add(name.length()));
		source = qn;
		this.name = name;
	}
	
	/** Create an UNqualified name (without a dot).
	 * @param loc location start
	 * @param name name referred to
	 */
	public QualName(Location loc, String name) {
		this(null,loc,name);
	}

	/**
	 * Get last part of a qualified name,
	 * @return last part of a qualified name.
	 */
	public String getLastSegment() {
		return name;
	}
	
	@Override
	public void prettyPrint(PrintWriter out) {
		if (source != null) {
			source.prettyPrint(out);
			out.append('.');
		}
		out.print(name);
	}

	/**
	 * Resolve this qualified name (see class documentation comment).
	 * @param ctx context to use, must not be null.
	 * @return resolved 
	 */
	public Object resolve(Context ctx) {
		if (version != ctx.version) resolution = null;
		if (resolution == null) {
			version = ctx.version;
			if (source == null) {
				resolution = ctx.modMap.get(name);
				if (resolution == null) resolution = ctx.synMap.get(name);
				if (resolution == null) resolution = ctx.ruleMap.get(name);
				if (resolution == null) resolution = ctx.judgMap.get(name);
				if (resolution == null) resolution = new String[]{name};
			} else {
				Object src = source.resolve(ctx);
				if (src == null) {
					return null;
				} else if (src instanceof Module) {
					// TODO: handle modules.
				} else if (src instanceof String[]) {
					String[] pack = (String[])src;
					ModuleId id = new ModuleId(pack,name);
					if (ctx.moduleFinder.hasCandidate(id)) {
						resolution = ctx.moduleFinder.findModule(id, this);
					} else {
						String[] newPack = new String[pack.length+1];
						resolution = newPack;
						System.arraycopy(pack, 0, newPack, 0, pack.length);
						newPack[pack.length] = name;
					}
				} else if (src != null) {
					ErrorHandler.report("Cannot look inside of " + name, this);
				}
			}
		}
		return resolution;
	}
}