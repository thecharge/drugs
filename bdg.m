function out = bdg(in)
%BDG     XPDE structure to find Bogoliubov sound wave modes
%
%   BDG(in) takes an XPDE input structure in of the form returned by
%   STATIC. It returns a similar input structure. This structure runs
%   after the equilibrium order parameter has been computed. It outputs a
%   field with 3*(nspace-1) components. Components 1:nspace-1 are the positive
%   BdG eigenvalues, nspace+1:2*(nspace-1) are the u modes, and the rest are
%   the v modes.  The missing mode is the ground state.
%
%   See also GROUND.


out.name = 'Bogoliubov initial state';
for s = {'dimension', 'fields', 'ranges', 'c', 'a', 'points'}
	if isfield(in, s{1}), out.(s{1}) = in.(s{1}); end
end

out.points(1) = 2;  out.ranges(1) = 1;
out.fields = 3*prod(out.points(2:end)) - 3;
out.observe = {};
out.transfer = @tfr;

end

function b = tfr(w,r,a0,r0)
	!rm -f debug1.mat debug2.mat

	% compute Bogoliubov modes
	a = squeeze(a0);  a = a(:);
	gs = r.points(2);

% Stub of 2D version
%	p = r.points;  g = r.ranges;
%	Dxx = kron(eye(p(3)), ssd(p(2), g(2)));
%	Dyy = kron(ssd(p(3), g(3)), eye(p(2)));
%	LAP = Dxx + Dyy;

	% see am.pdf an.pdf ao.pdf
	% mu = 1971.42857143;
	mu = 1971.42857142858;	% from r.a.g*a.^2

	LAP = ssd(r.points(2), r.ranges(2)/2);
	K = diag(r.a.K(r0) - mu) + diag(2*r.a.g*abs(a).^2);
	M = mu*eye(r.points(2));
	Bother = diag(r.a.g*abs(a).^2);
	Bself = -LAP + diag(r.a.K(r0)) + 2*Bother;
	BdG = [Bself-M, -Bother; Bother, -Bself+M];
	% project onto space orthogonal to a0
	[U1,~] = qr([a eye(numel(a), numel(a)-1)]);  U1 = U1(:, 2:end);
	U = kron(eye(2), U1);
	tic; [ev,ew] = eig(U'*BdG*U, 'vector'); toc

	save debug1.mat

	assert(norm(imag(ew)) / norm(ew) < 1e-5), ew = real(ew);
	
	% remove (u,v,e) (v,u,-e) degeneracy and sort by increasing eigenvalue
	ev = ev(:, ew>0);  ew = ew(ew>0);
	[ew, i] = sort(ew);  ev = ev(:,i);
	
	% Fix numerical quirk where some modes are elliptically polarised
	% N.B. this works so far, but might not be a general solution
	bmod = U*ev;
	ixodd = find(sqrt(sum(imag(ev).^2)) > 0.1);
	for i = 1:2:length(ixodd)
		ix = ixodd(i);
		bmod(:,ix:ix+1) = [real(bmod(:,ix)) imag(bmod(:,ix))];
		bmod(:,ix) = bmod(:,ix) / norm(bmod(:,ix));
		bmod(:,ix+1) = bmod(:,ix+1) / norm(bmod(:,ix+1));
	end
	
	% separate u and v modes, then normalise
	buv = reshape(bmod,gs,2,[]);
	c = r.dV*sum(abs(buv(:,1,:)).^2 - abs(buv(:,2,:)).^2);
	c = 1./sqrt(c);
	buv = buv.*repmat(c,gs,2,1);

	b = [repmat(ew, 1, r.nspace); squeeze(buv(:,1,:))'; squeeze(buv(:,2,:))'];
	
	save debug2.mat
end