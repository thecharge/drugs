# Find principal axes of the trap potential

N = 7e3;		# nominal number of atoms

function [x, y, z, K] = loadk(t, U, r0)
	% load potential in dispersion um, rotate to prinaxes.
	load(['potentials/RWA_X_3D_' int2str(t) '.mat'])
	K = 17.19*v;  K = K - min(K(:));
	if nargin == 1, return, endif
	x1 = x-r0(1);  y1 = y - r0(2);  z1 = z-r0(3);
	[X, Y, Z] = ndgrid(x1, y1, z1);
	R = U*[X(:) Y(:) Z(:)]';
	# interp3 takes meshgrid order, reshape takes ndgrid order
	K = interp3(y1, x1, z1, K, R(2,:), R(1,:), R(3,:));
	K = reshape(K, size(X));
endfunction

function [r, rho] = tcent(x, y, z, K)
	% centre of mass of a thermal cloud
	[X,Y,Z] = ndgrid(x,y,z);
	rho = exp(-K/(2*0.25^2));  rho = rho(:);
	r = [X(:) Y(:) Z(:)]'*rho/sum(rho);
endfunction

% find principal axes of parallel lines of atoms
[x, y, z, K] = loadk(17);

# find nominal density, shift origin to centre of mass
[r0, rho] = tcent(x,y,z,K);
xa = x-r0(1);  ya = y - r0(2);  za = z-r0(3);
[X,Y,Z] = ndgrid(xa,ya,za);
X = X(:);  Y = Y(:);  Z = Z(:);

# plot section through centre of mass
# figure
# zmin = round(interp1(za,1:length(za),0));
# contour(xa,ya,K(:,:,zmin),linspace(0,sqrt(2),10).^2)
# xlabel x;  ylabel y;  title('Transverse section near bottom of trap, za = ' + string(za(zmin)))

# inertia matrix
I = diag(([Y X X].^2+[Z Z Y].^2)'*rho);
I([2 3 6]) = -[X.*Y  X.*Z Y.*Z]'*rho;
I([4 7 8]) = I([2 3 6]);

# principal axes, in x y z order, projected into xz plane.
[U, ~] = eig(I);
[~, k] = max(abs(U'));
U = U(:,k);  U([2 4 6 8]) = 0;
for i = 1:3
	U(:,i) = sign(U(i,i))*U(:,i)/norm(U(:,i));
end
