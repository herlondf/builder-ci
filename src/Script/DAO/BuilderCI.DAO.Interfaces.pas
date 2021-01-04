unit BuilderCI.DAO.Interfaces;

interface

type
  iDAOScript = interface
    procedure Make;
    procedure Version;
    procedure Send(aDirect: Boolean = False);
  end;

implementation

end.
